terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateazuregitea"
    container_name       = "tfstate"
    key                  = "gitea-demo.terraform.tfstate"
  }
}
