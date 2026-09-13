resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-ghost-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-ghost-${var.environment}"

  role_based_access_control_enabled = true
  azure_policy_enabled              = true
  automatic_channel_upgrade         = "patch"
  local_account_disabled            = true

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges != null ? var.api_server_authorized_ip_ranges : ["0.0.0.0/0"]

  # 1. System Node Pool (Critical System Pods Only)
  default_node_pool {
    name                         = "systempool"
    node_count                   = 2
    vm_size                      = "Standard_B2s"
    vnet_subnet_id               = var.subnet_id
    os_disk_size_gb              = 30
    max_pods                     = 50
    enable_host_encryption       = true
    only_critical_addons_enabled = true
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

# 2. Non-Production Node Pool (Test & Acceptance Workloads)
resource "azurerm_kubernetes_cluster_node_pool" "nonprod" {
  name                   = "nonprodpool"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  vm_size                = "Standard_B2s"
  node_count             = 2
  vnet_subnet_id         = var.subnet_id
  os_disk_size_gb        = 30
  max_pods               = 50
  enable_host_encryption = true

  node_labels = {
    "workload"    = "nonprod"
    "environment" = "test-acc"
  }
}

# 3. Production Node Pool (Isolated with Taint)
resource "azurerm_kubernetes_cluster_node_pool" "prod" {
  name                   = "prodpool"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  vm_size                = "Standard_D2s_v5" # Higher performance SKU
  node_count             = 2
  vnet_subnet_id         = var.subnet_id
  os_disk_size_gb        = 50
  max_pods               = 50
  enable_host_encryption = true

  node_labels = {
    "workload"    = "production"
    "environment" = "prod"
  }

  node_taints = [
    "workload=production:NoSchedule"
  ]
}