variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "environment" {
  type        = string
  default     = "shared"
  description = "Cluster environment identifier"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for AKS node pools"
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  default     = null
  description = "Allowed IP ranges for Kubernetes API server"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "ID of the Log Analytics Workspace for OMS Agent"
}