resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ghost-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "nsg-aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "nsg-db-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_subnet_prefix
}

resource "azurerm_subnet_network_security_group_association" "aks_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-db"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.db_subnet_prefix

  delegation {
    name = "fs-delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}