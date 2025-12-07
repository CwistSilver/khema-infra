variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the shared resource group"
  type        = string
  default     = "rg-khema-shared"
}

variable "postgresql_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU name (B_Standard_B1ms is cheapest)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768 # 32GB
}

variable "container_registry_sku" {
  description = "Container Registry SKU (Basic is cheapest)"
  type        = string
  default     = "Basic"
}

variable "key_vault_sku" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
}

variable "langfuse_secret_salt" {
  description = "Langfuse secret salt"
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret"
  type        = string
  sensitive   = true
}

variable "encryption_key" {
  description = "Encryption key for Langfuse"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
