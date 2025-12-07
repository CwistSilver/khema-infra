variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "shared_resource_group_name" {
  description = "Name of the shared resource group"
  type        = string
  default     = "rg-khema-shared"
}

variable "postgresql_server_name" {
  description = "Name of the existing PostgreSQL server"
  type        = string
  default     = "khema-postgresql"
}

variable "postgresql_database_name" {
  description = "Name of the database for Langfuse"
  type        = string
  default     = "langfuse_prod"
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
  description = "Secret salt for Langfuse (min 32 characters)"
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret (min 32 characters)"
  type        = string
  sensitive   = true
}

variable "nextauth_url" {
  description = "NextAuth URL (will be the container app URL)"
  type        = string
}
