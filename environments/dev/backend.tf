# Backend configuration for Terraform state
#
# For local development, state is stored locally
# For production use, uncomment and configure Azure Storage backend
#
# To set up Azure Storage backend:
# 1. Create a storage account and container for Terraform state
# 2. Uncomment the terraform block below
# 3. Run: tofu init -migrate-state
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-khema-terraform"
#     storage_account_name = "stkhematerraform"
#     container_name       = "tfstate"
#     key                  = "dev.terraform.tfstate"
#   }
# }
