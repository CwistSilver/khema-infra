terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group for Development Environment
resource "azurerm_resource_group" "dev" {
  name     = "rg-khema-dev"
  location = var.location

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Langfuse Module
module "langfuse" {
  source = "../../modules/langfuse"

  environment                 = "dev"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.dev.name
  shared_resource_group_name  = var.shared_resource_group_name
  postgresql_server_name      = var.postgresql_server_name
  postgresql_database_name    = var.postgresql_database_name
  postgresql_admin_username   = var.postgresql_admin_username
  postgresql_admin_password   = var.postgresql_admin_password
  langfuse_secret_salt        = var.langfuse_secret_salt
  nextauth_secret             = var.nextauth_secret
  nextauth_url                = var.nextauth_url
  container_app_min_replicas  = 0  # Scale to zero in dev
  container_app_max_replicas  = 5
  container_cpu               = "0.5"
  container_memory            = "1Gi"
  redis_sku                   = "Basic"
  redis_family                = "C"
  redis_capacity              = 0

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
