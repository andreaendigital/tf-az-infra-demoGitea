# Using local backend for now - Azure CLI not installed on Jenkins
# TODO: Install Azure CLI on Jenkins server, then switch to remote backend

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate-rg"
#     storage_account_name = "tfstateazuregitea"
#     container_name       = "tfstate"
#     key                  = "gitea-demo.terraform.tfstate"
#   }
# }
