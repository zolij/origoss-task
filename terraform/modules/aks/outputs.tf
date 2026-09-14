output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  description = "Raw Kubernetes configuration credentials."
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig string."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}