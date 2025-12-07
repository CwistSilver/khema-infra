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
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Shared Resources Module
module "shared_resources" {
  source = "./modules/shared-resources"

  location                  = var.location
  resource_group_name       = "rg-khema-shared"
  postgresql_admin_username = var.postgresql_admin_username
  postgresql_admin_password = var.postgresql_admin_password
  postgresql_sku_name       = "B_Standard_B1ms" # Cheapest option (~18$/month)
  postgresql_storage_mb     = 32768             # 32GB
  container_registry_sku    = "Basic"           # Cheapest ACR

  tags = {
    ManagedBy   = "Terraform"
    Environment = "shared"
    Project     = "Khema"
  }
}

# Langfuse VM Module
module "langfuse" {
  source = "./modules/langfuse-vm"

  location                  = var.location
  resource_group_name       = "rg-khema-langfuse"
  vm_size                   = "Standard_B2s" # 2 vCPU, 4GB RAM (~30€/month)
  admin_username            = var.vm_admin_username
  ssh_public_key            = var.ssh_public_key
  postgresql_host           = module.shared_resources.postgresql_server_fqdn
  postgresql_admin_username = var.postgresql_admin_username
  postgresql_admin_password = var.postgresql_admin_password
  langfuse_secret_salt      = var.langfuse_secret_salt
  nextauth_secret           = var.nextauth_secret
  encryption_key            = var.encryption_key

  tags = {
    ManagedBy   = "Terraform"
    Environment = "production"
    Project     = "Khema"
    Service     = "Langfuse"
  }

  depends_on = [module.shared_resources]
}
