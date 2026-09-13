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
  description = "Deployment environment name"
}

variable "vnet_id" {
  type        = string
  description = "ID of the Virtual Network for DNS linking"
}

variable "delegated_subnet_id" {
  type        = string
  description = "Subnet ID delegated to MySQL Flexible Server"
}

variable "db_admin_user" {
  type        = string
  description = "MySQL administrator username"
}

variable "db_admin_password" {
  type        = string
  sensitive   = true
  description = "MySQL administrator password"
}

variable "sku_name" {
  type        = string
  default     = "B_Standard_B1ms"
  description = "SKU for MySQL Flexible Server"
}