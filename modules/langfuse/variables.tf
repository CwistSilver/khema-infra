variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "shared_resource_group_name" {
  description = "Name of the shared resource group containing PostgreSQL"
  type        = string
  default     = "rg-khema-shared"
}

variable "postgresql_server_name" {
  description = "Name of the existing PostgreSQL server"
  type        = string
  default     = "khema-postgresql"
}

variable "postgresql_database_name" {
  description = "Name of the database to create for Langfuse"
  type        = string
  default     = "langfuse"
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
  description = "Secret salt for Langfuse encryption (min 32 characters)"
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret for authentication (min 32 characters)"
  type        = string
  sensitive   = true
}

variable "nextauth_url" {
  description = "NextAuth URL (will be set to the container app URL)"
  type        = string
}

variable "container_app_min_replicas" {
  description = "Minimum number of replicas (0 for scale to zero)"
  type        = number
  default     = 0
}

variable "container_app_max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "container_cpu" {
  description = "CPU cores per container"
  type        = string
  default     = "1.0"
}

variable "container_memory" {
  description = "Memory per container"
  type        = string
  default     = "2Gi"
}

variable "redis_sku" {
  description = "Redis cache SKU"
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "Redis cache family"
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Redis cache capacity"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
