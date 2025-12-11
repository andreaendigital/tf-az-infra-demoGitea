# environments/demo/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatecicd2024"
    container_name       = "tfstate"
    key                  = "demo.terraform.tfstate"
  }
}
