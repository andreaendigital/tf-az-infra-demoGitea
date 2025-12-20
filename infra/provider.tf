terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
  }

  # Backend configuration for remote state
  # Prevents state loss when Jenkins workspace is cleaned
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateazgitea"
    container_name       = "tfstate"
    key                  = "gitea-azure-infra.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = true
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
