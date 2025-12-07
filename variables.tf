variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "postgresql_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password (min 8 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.postgresql_admin_password) >= 8
    error_message = "PostgreSQL password must be at least 8 characters long."
  }
}

variable "vm_admin_username" {
  description = "Admin username for the Langfuse VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (contents of ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "langfuse_secret_salt" {
  description = "Secret salt for Langfuse encryption (min 32 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.langfuse_secret_salt) >= 32
    error_message = "Langfuse secret salt must be at least 32 characters long."
  }
}

variable "nextauth_secret" {
  description = "NextAuth secret for authentication (min 32 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.nextauth_secret) >= 32
    error_message = "NextAuth secret must be at least 32 characters long."
  }
}

variable "encryption_key" {
  description = "Encryption key for sensitive data (64 hex characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.encryption_key) == 64
    error_message = "Encryption key must be exactly 64 hex characters (256 bits)."
  }
}
