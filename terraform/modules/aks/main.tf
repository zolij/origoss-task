resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-ghost-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-ghost-${var.environment}"

  default_node_pool {
    name            = "systempool"
    node_count      = var.node_count
    vm_size         = var.vm_size
    vnet_subnet_id  = var.subnet_id
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}