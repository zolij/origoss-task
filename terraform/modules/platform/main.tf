# Traefik Ingress Controller
resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = "26.0.0"
  namespace        = "traefik"
  create_namespace = true

  set {
    name  = "nodeSelector.workload"
    value = "system"
  }
}

# Cert-Manager for Automated TLS
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.14.4"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "nodeSelector.workload"
    value = "system"
  }
}