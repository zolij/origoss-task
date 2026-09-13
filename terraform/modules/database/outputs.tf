output "mysql_fqdn" {
  value       = azurerm_mysql_flexible_server.db.fqdn
  description = "FQDN of the MySQL Flexible Server"
}

output "database_name" {
  value       = azurerm_mysql_flexible_database.ghost_db.name
  description = "Name of the created Ghost database"
}