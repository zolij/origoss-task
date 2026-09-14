terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-ghost-${var.environment}"
  location = var.location
}

module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
}

module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
  vnet_id             = module.network.vnet_id
  delegated_subnet_id = module.network.db_subnet_id
  db_admin_user       = var.db_admin_user
  db_admin_password   = var.db_admin_password
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "law-ghost-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "aks" {
  source                     = "./modules/aks"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  environment                = var.environment
  subnet_id                  = module.network.aks_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

module "platform" {
  source = "./modules/platform"

  # Explicit dependency to ensure the AKS control plane is reachable
  depends_on = [module.aks]
}