terraform {
  backend "azurerm" {
    # Backend configuration will be provided via:
    # 1. Command line: terraform init -backend-config=...
    # 2. Jenkins credentials
    # 3. Environment variables
    
    # Example configuration (do not uncomment, set via Jenkins):
    # resource_group_name  = "tfstate"
    # storage_account_name = "tfstateazuregitea"
    # container_name       = "tfstate"
    # key                  = "gitea-demo.terraform.tfstate"
  }
}
