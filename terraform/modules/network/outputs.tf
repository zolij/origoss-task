output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the Virtual Network"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks_subnet.id
  description = "ID of the AKS subnet"
}

output "db_subnet_id" {
  value       = azurerm_subnet.db_subnet.id
  description = "ID of the Database delegated subnet"
}