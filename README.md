# origoss-task

Terraform + Kubernetes deployment of a Ghost CMS platform on Azure AKS.

## Repository Layout

- `terraform/` — Azure infrastructure (VNet, AKS, MySQL Flexible Server, Log Analytics) and cluster platform (Traefik, cert-manager via Helm).
- `k8s/` — Kubernetes manifests: cert-manager `ClusterIssuer`, `test` namespace with quotas, network isolation policy.
- `helm/` — Helm values for the Ghost CMS chart per environment.
- `docs/` — [Architecture documentation](docs/ARCHITECTURE.md) and [architecture diagram](docs/architecture.drawio) (draw.io format).

## Getting Started

```bash
cd terraform
terraform init
terraform plan -var="db_admin_password=<secret>"
terraform apply -var="db_admin_password=<secret>"
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full details on modules, dependencies, and the deployed platform.
