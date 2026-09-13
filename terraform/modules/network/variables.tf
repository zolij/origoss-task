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

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for the VNet"
}

variable "aks_subnet_prefix" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "Address prefix for the AKS subnet"
}

variable "db_subnet_prefix" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "Address prefix for the Database subnet"
}