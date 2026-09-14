# Architecture Documentation

This repository provisions the Azure infrastructure and Kubernetes platform required to run a **Ghost CMS** deployment on **AKS**, using Terraform for infrastructure/platform provisioning and Helm/Kubernetes manifests for the application and cluster policies.

A visual diagram is available at [architecture.drawio](architecture.drawio) (open with [draw.io](https://app.diagrams.net/) or the VS Code Draw.io Integration extension).

## Overview

| Layer | Tooling | Purpose |
|---|---|---|
| Infrastructure | Terraform (`terraform/`) | Azure networking, AKS cluster, MySQL database, Log Analytics |
| Cluster platform | Terraform + Helm (`modules/platform`) | Ingress controller (Traefik) and TLS automation (cert-manager) |
| Cluster policy | Kubernetes manifests (`k8s/`) | Namespace, quotas, network isolation, ClusterIssuer |
| Application | Helm values (`helm/values-test.yaml`) | Ghost CMS chart configuration for the `test` environment |

## Terraform Module Layout

```
terraform/
├── main.tf            # Root module: resource group, log analytics, wires up child modules
├── variables.tf        # location, environment, db_admin_user, db_admin_password
├── outputs.tf          # resource_group_name, aks_cluster_name, mysql_fqdn
├── versions.tf          # terraform >= 1.5.0, azurerm >= 3.90.0, helm ~> 2.12.0
└── modules/
    ├── network/        # VNet, subnets, NSGs
    ├── database/        # Private DNS zone + MySQL Flexible Server
    ├── aks/             # AKS cluster + node pools
    └── platform/        # Helm releases: Traefik, cert-manager
```

### Root module (`terraform/main.tf`)

- Creates `azurerm_resource_group.rg` (`rg-ghost-{environment}`).
- Creates `azurerm_log_analytics_workspace.logs` (`law-ghost-{environment}`, 30-day retention, PerGB2018).
- Instantiates `network`, `database`, `aks`, `platform` modules in that dependency order.
- Configures the `helm` provider dynamically from `module.aks.kube_config`, so Helm releases in the `platform` module authenticate against the freshly created AKS cluster.
- No remote backend is configured — state is local (`terraform.tfstate`). Consider migrating to an Azure Storage Account backend for team use.

### `modules/network`

Creates the VNet and subnets used by the rest of the platform.

| Resource | Name | Notes |
|---|---|---|
| `azurerm_virtual_network` | `vnet-ghost-{environment}` | Default `10.0.0.0/16` |
| `azurerm_subnet` (`snet-aks`) | AKS subnet | Default `10.0.1.0/24` |
| `azurerm_subnet` (`snet-db`) | DB subnet | Default `10.0.2.0/24`, delegated to `Microsoft.DBforMySQL/flexibleServers` |
| `azurerm_network_security_group` | `nsg-aks-{environment}` | Attached to AKS subnet |
| `azurerm_network_security_group` | `nsg-db-{environment}` | Attached to DB subnet |

**Outputs:** `vnet_id`, `aks_subnet_id`, `db_subnet_id` — consumed by the `database` and `aks` modules.

### `modules/database`

| Resource | Name | Notes |
|---|---|---|
| `azurerm_private_dns_zone` | `ghost-{environment}.mysql.database.azure.com` | Private DNS for MySQL |
| `azurerm_private_dns_zone_virtual_network_link` | — | Links the zone to the VNet |
| `azurerm_mysql_flexible_server` | `mysql-ghost-{environment}` | SKU `B_Standard_B1ms` (default), zone 1, 7-day backup, no geo-redundancy, placed in the delegated DB subnet |
| `azurerm_mysql_flexible_database` | `ghost` | `utf8mb4` / `utf8mb4_unicode_ci` |

**Inputs:** `vnet_id`, `delegated_subnet_id` (from `network`), `db_admin_user`, `db_admin_password`.
**Outputs:** `mysql_fqdn`, `database_name` — the FQDN is surfaced as a root output and consumed by the Ghost Helm values.

### `modules/aks`

| Resource | Name | Notes |
|---|---|---|
| `azurerm_kubernetes_cluster` | `aks-ghost-{environment}` | RBAC + Azure Policy enabled, local accounts disabled, Azure CNI + Azure Network Policy, standard load balancer, Key Vault secret rotation, optional OMS agent |
| System node pool | `systempool` | 2 × `Standard_B2s`, `CriticalAddonsOnly` taint, 30 GB disk, host encryption |
| `azurerm_kubernetes_cluster_node_pool` | `nonprodpool` | 2 × `Standard_B2s`, labels `workload=nonprod`, `environment=test-acc` |
| `azurerm_kubernetes_cluster_node_pool` | `prodpool` | 2 × `Standard_D2s_v5`, labels `workload=production`, taint `workload=production:NoSchedule` |

**Inputs:** `subnet_id` (AKS subnet from `network`), `log_analytics_workspace_id`, `api_server_authorized_ip_ranges`.
**Outputs:** `cluster_id`, `cluster_name`, `kube_config`, `kube_config_raw` (sensitive) — used to configure the `helm` provider for `platform`.

### `modules/platform`

Deploys cluster-wide Helm releases, scheduled onto the system node pool (`nodeSelector: workload=system`):

| Release | Chart | Version | Namespace |
|---|---|---|---|
| Traefik | `traefik/traefik` | `26.0.0` | `traefik` |
| cert-manager | `jetstack/cert-manager` | `1.14.4` | `cert-manager` (CRDs installed) |

Has an explicit `depends_on = [module.aks]` to guarantee the cluster API is reachable before Helm attempts to connect.

## Kubernetes Manifests (`k8s/`)

| File | Resource | Purpose |
|---|---|---|
| `cert-manager/cluster-issuer.yaml` | `ClusterIssuer/letsencrypt-prod` | ACME (Let's Encrypt production) issuer, HTTP-01 challenge solved via Traefik ingress class |
| `namespaces/test-namespace.yaml` | `Namespace/test`, `ResourceQuota`, `LimitRange` | `test` namespace capped at 4 CPU / 4Gi mem / 10 pods; default container requests/limits 100m/256Mi – 500m/512Mi |
| `networkpolicies/test-isolation.yaml` | `NetworkPolicy/isolate-test-environment` | Allows intra-namespace traffic and ingress from the Traefik namespace; allows DNS egress to `kube-system`; blocks egress to the AKS node subnet (`10.0.1.0/24`) while allowing other outbound traffic |

## Application Deployment (`helm/values-test.yaml`)

Helm values for the [Bitnami `ghost` chart](https://github.com/bitnami/charts/tree/main/bitnami/ghost) (`bitnami/ghost`, repo `https://charts.bitnami.com/bitnami`), `test` environment:

- **Database:** external MySQL, host `mysql-ghost-test.ghost-test.mysql.database.azure.com`, port 3306, user `ghostadmin`, database `ghost_test` (matches the Terraform `database` module output).
- **Ghost host/protocol:** `test.blog.mycompany.com` over `https`.
- **Persistence:** enabled, `managed-csi` storage class, 5Gi, `ReadWriteOnce`.
- **Scheduling:** targets the `nonprodpool` node pool via `nodeSelector: workload=nonprod`.
- **Security context:** pod `fsGroup: 1001`; container `runAsUser: 1001`, `runAsNonRoot: true`.
- **Ingress:** enabled, `traefik` ingress class, TLS via the `letsencrypt-prod` `ClusterIssuer`.
- **Resources:** requests `100m`/`256Mi`, limits `500m`/`512Mi`.

### Installing the chart

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install ghost-test bitnami/ghost \
  --namespace test \
  --values helm/values-test.yaml
```

## End-to-End Request Flow

1. DNS for `test.blog.mycompany.com` resolves to the Traefik ingress controller's public load balancer IP.
2. Traefik (running on the AKS system node pool) terminates TLS using a certificate issued by cert-manager via the `letsencrypt-prod` `ClusterIssuer` (HTTP-01 challenge).
3. Traefik routes the request to the Ghost CMS pod running in the `test` namespace on the `nonprodpool` node pool.
4. The Ghost pod connects to the MySQL Flexible Server over the private VNet link/delegated subnet to read/write the `ghost_test` database.
5. `NetworkPolicy` in the `test` namespace restricts pod egress/ingress; `ResourceQuota`/`LimitRange` cap the namespace's compute footprint.
6. AKS control-plane and node diagnostics flow to the Log Analytics workspace for observability.

## Security Notes

- MySQL Flexible Server has no public endpoint; it is reachable only via the private DNS zone linked to the VNet.
- AKS: RBAC enabled, local accounts disabled, Azure Policy enabled, host encryption on all node pools, Key Vault secret rotation enabled.
- Production workloads are isolated onto a dedicated, tainted node pool (`prodpool`).
- Ghost containers run as a non-root user (UID 1001).
- Secrets (`db_admin_password`) are marked `sensitive` in Terraform and should be supplied via a secure variable source (e.g., `TF_VAR_db_admin_password`, a `.tfvars` file excluded from VCS, or a secrets manager) — never committed to source control.
