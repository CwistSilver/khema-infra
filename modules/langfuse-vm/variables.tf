variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the Langfuse resource group"
  type        = string
  default     = "rg-khema-langfuse"
}

variable "vm_size" {
  description = "VM size (B2s is good for Langfuse)"
  type        = string
  default     = "Standard_B2s" # 2 vCPU, 4GB RAM, ~30€/month
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "postgresql_host" {
  description = "PostgreSQL server FQDN"
  type        = string
}

variable "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "langfuse_secret_salt" {
  description = "Langfuse secret salt (min 32 characters)"
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret (min 32 characters)"
  type        = string
  sensitive   = true
}

variable "encryption_key" {
  description = "Encryption key for sensitive data (64 hex characters)"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
