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

## Deploying Ghost (Bitnami Helm chart)

The application layer uses the [Bitnami `ghost` chart](https://github.com/bitnami/charts/tree/main/bitnami/ghost). After the Terraform infrastructure and platform (AKS, Traefik, cert-manager) are provisioned:

```bash
# Add the Bitnami chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create the target namespace (or apply k8s/namespaces/test-namespace.yaml)
kubectl create namespace test

# Install/upgrade Ghost using the environment-specific values file
helm upgrade --install ghost-test bitnami/ghost \
  --namespace test \
  --values helm/values-test.yaml
```

> **Note:** [helm/values-test.yaml](helm/values-test.yaml) contains a plaintext `externalDatabase.password` for convenience. For anything beyond local/test use, override it at install time instead of committing it, e.g. `--set externalDatabase.password=<secret>` or `--set-file` from a secret manager, and remove the value from the checked-in file.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full details on modules, dependencies, and the deployed platform.
