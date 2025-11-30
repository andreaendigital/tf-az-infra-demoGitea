terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group para el ambiente demo
resource "azurerm_resource_group" "demo" {
  name     = "rg-demo-cicd"
  location = "East US"
  
  tags = {
    environment = "demo"
    project     = "ci-cd-pipeline"
    created-by  = "terraform"
  }
}

# Network Security Group con reglas básicas
resource "azurerm_network_security_group" "demo" {
  name                = "nsg-demo-cicd"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Jenkins"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "demo"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.demo.name
}

output "resource_group_location" {
  value = azurerm_resource_group.demo.location
}

output "network_security_group_id" {
  value = azurerm_network_security_group.demo.id
}
