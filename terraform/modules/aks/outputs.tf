output "cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Name of the AKS cluster"
}

output "cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "ID of the AKS cluster"
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  description = "Object ID of the Kubelet Managed Identity"
}