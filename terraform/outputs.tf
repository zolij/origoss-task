output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group name"
}

output "aks_cluster_name" {
  value       = module.aks.cluster_name
  description = "AKS Cluster name"
}

output "mysql_fqdn" {
  value       = module.database.mysql_fqdn
  description = "MySQL FQDN endpoint"
}