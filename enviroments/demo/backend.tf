module "resource_group" {
  source = "../../modules/resource-group"

  project_name = "ci-cd-pipeline"
  environment  = "demo"
  location     = "East US"
  tags = {
    project     = "ci-cd-pipeline"
    team        = "devops"
    cost-center = "it-001"
  }
}

module "network" {
  source = "../../modules/network"

  resource_group_name = module.resource_group.name
  environment        = "demo"
  project_name       = "ci-cd-pipeline"
  location          = "East US"

  security_rules = [
    {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "HTTP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
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
  ]
}
