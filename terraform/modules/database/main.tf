resource "azurerm_private_dns_zone" "db_dns" {
  name                = "ghost-${var.environment}.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "db_dns_link" {
  name                  = "vnet-link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.db_dns.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_mysql_flexible_server" "db" {
  name                   = "mysql-ghost-${var.environment}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.db_admin_user
  administrator_password = var.db_admin_password

  sku_name            = var.sku_name
  zone                = "1"
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.db_dns.id

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
}

resource "azurerm_mysql_flexible_database" "ghost_db" {
  name                = "ghost"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}