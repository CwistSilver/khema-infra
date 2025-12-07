# Backend configuration for Terraform state
#
# PRODUCTION MUST USE REMOTE STATE!
# Uncomment and configure Azure Storage backend before deploying to production
#
# To set up Azure Storage backend:
# 1. Create a storage account and container for Terraform state
# 2. Enable versioning and soft delete on the container
# 3. Uncomment the terraform block below
# 4. Run: tofu init -migrate-state
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-khema-terraform"
#     storage_account_name = "stkhematerraform"
#     container_name       = "tfstate"
#     key                  = "prod.terraform.tfstate"
#   }
# }
