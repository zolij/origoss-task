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

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the AKS default node pool"
}

variable "node_count" {
  type        = number
  default     = 2
  description = "Number of worker nodes"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "VM size for worker nodes"
}