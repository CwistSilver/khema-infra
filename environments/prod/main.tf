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
      prevent_deletion_if_contains_resources = true
    }
  }
}

# Resource Group for Production Environment
resource "azurerm_resource_group" "prod" {
  name     = "rg-khema-prod"
  location = var.location

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

# Langfuse Module
module "langfuse" {
  source = "../../modules/langfuse"

  environment                 = "prod"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.prod.name
  shared_resource_group_name  = var.shared_resource_group_name
  postgresql_server_name      = var.postgresql_server_name
  postgresql_database_name    = var.postgresql_database_name
  postgresql_admin_username   = var.postgresql_admin_username
  postgresql_admin_password   = var.postgresql_admin_password
  langfuse_secret_salt        = var.langfuse_secret_salt
  nextauth_secret             = var.nextauth_secret
  nextauth_url                = var.nextauth_url
  container_app_min_replicas  = 1  # Always at least 1 replica in prod
  container_app_max_replicas  = 20
  container_cpu               = "1.0"
  container_memory            = "2Gi"
  redis_sku                   = "Standard"
  redis_family                = "C"
  redis_capacity              = 1

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
