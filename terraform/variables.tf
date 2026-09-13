variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure region for all resources"
}

variable "environment" {
  type        = string
  default     = "test"
  description = "Deployment environment (e.g., test, acc, prod)"
}

variable "db_admin_user" {
  type        = string
  default     = "ghostadmin"
  description = "MySQL administrator username"
}

variable "db_admin_password" {
  type        = string
  sensitive   = true
  description = "MySQL administrator password"
}