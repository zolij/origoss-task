resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-ghost-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-ghost-${var.environment}"

  # Governance & Lifecycle
  role_based_access_control_enabled = true
  azure_policy_enabled              = true
  automatic_channel_upgrade         = "patch"
  local_account_disabled            = true

  # Set default allow-all for authorized ranges if not explicitly scoped
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges != null ? var.api_server_authorized_ip_ranges : ["0.0.0.0/0"]

  # SKU tier: "Free" for test/dev, "Standard" for Production (CKV_AZURE_170)
  sku_tier = var.environment == "prod" ? "Standard" : "Free"

  default_node_pool {
    name                 = "systempool"
    node_count           = var.node_count
    vm_size              = var.vm_size
    vnet_subnet_id       = var.subnet_id
    os_disk_size_gb      = 30
    max_pods             = 50
    enable_host_encryption = true
    only_critical_addons_enabled = false # Set true in production when dedicated user node pool is present
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }
}