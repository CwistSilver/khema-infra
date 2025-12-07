# Backend configuration for Terraform state
#
# For local development, state is stored locally in terraform.tfstate
# For production use, configure Azure Storage backend:
#
# 1. Create storage account for Terraform state:
#    az storage account create \
#      --name stkhematerraform \
#      --resource-group rg-khema-shared \
#      --location westeurope \
#      --sku Standard_LRS
#
# 2. Create container:
#    az storage container create \
#      --name tfstate \
#      --account-name stkhematerraform
#
# 3. Uncomment the terraform block below
#
# 4. Run: tofu init -migrate-state
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-khema-shared"
#     storage_account_name = "stkhematerraform"
#     container_name       = "tfstate"
#     key                  = "khema-infra.tfstate"
#   }
# }
