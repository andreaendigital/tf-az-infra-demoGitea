# ====================================
# Networking - VNet, Subnets, NSG, VPN Gateway
# ====================================

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_address_space]

  tags = merge(var.tags, {
    environment = var.environment
    component   = "networking"
  })
}

# Subnet for Application (VM)
resource "azurerm_subnet" "app" {
  name                 = "subnet-app-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_app_address_prefix]
  # Wait for VPN Gateway to complete to avoid concurrent operation conflicts
  depends_on = [azurerm_virtual_network_gateway.main]

  timeouts {
    create = "90m"
    update = "90m"
    delete = "30m"
  }
}

# Subnet for Database
resource "azurerm_subnet" "database" {
  name                 = "subnet-database-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_database_address_prefix]

  # Wait for VPN Gateway to complete to avoid concurrent operation conflicts
  depends_on = [azurerm_virtual_network_gateway.main]

  timeouts {
    create = "90m"
    update = "90m"
    delete = "30m"
  }
}

# Subnet for VPN Gateway
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"  # Name MUST be GatewaySubnet
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_gateway_address_prefix]

  timeouts {
    create = "90m"
    update = "90m"
    delete = "30m"
  }
}

# Network Security Group for Application Subnet
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # SSH access (restricted to specific IPs if provided)
  dynamic "security_rule" {
    for_each = length(var.allowed_ssh_ips) > 0 ? var.allowed_ssh_ips : (var.admin_source_ip != "" ? [var.admin_source_ip] : ["*"])
    content {
      name                       = "AllowSSH-${security_rule.key}"
      priority                   = 1001 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  # HTTP for Gitea web interface
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Gitea web port (3000)
  security_rule {
    name                       = "AllowGiteaWeb"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow communication with database subnet
  security_rule {
    name                       = "AllowDatabaseSubnet"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.subnet_app_address_prefix
    destination_address_prefix = var.subnet_database_address_prefix
  }

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Associate NSG with App Subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

# Network Security Group for Database Subnet
resource "azurerm_network_security_group" "database" {
  name                = "nsg-database-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SSH for Ansible setup (replica-only mode only)
  dynamic "security_rule" {
    for_each = var.deployment_mode == "replica-only" ? [1] : []
    content {
      name                       = "AllowSSHForAnsible"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  # Allow MySQL from app subnet only
  security_rule {
    name                       = "AllowMySQLFromApp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.subnet_app_address_prefix
    destination_address_prefix = "*"
  }

  # Allow MySQL replication from AWS (if VPN is enabled)
  dynamic "security_rule" {
    for_each = var.enable_vpn_gateway && var.aws_vpc_cidr != "" ? [1] : []
    content {
      name                       = "AllowMySQLFromAWS"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = var.aws_vpc_cidr
      destination_address_prefix = "*"
    }
  }

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Associate NSG with Database Subnet
resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id

  timeouts {
    create = "90m"
    update = "90m"
    delete = "40m"
  }
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway" {
  count               = var.deployment_mode == "replica-only" ? 1 : 0
  name                = "pip-vpngateway-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# VPN Gateway (only in replica-only mode)
resource "azurerm_virtual_network_gateway" "main" {
  count               = var.deployment_mode == "replica-only" ? 1 : 0
  name                = "vpngw-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Local Network Gateway (AWS side)
resource "azurerm_local_network_gateway" "aws" {
  count               = var.deployment_mode == "replica-only" && var.aws_vpn_gateway_ip != "" ? 1 : 0
  name                = "lng-aws-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = var.aws_vpn_gateway_ip
  address_space       = [var.aws_vpc_cidr]

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# VPN Connection to AWS
resource "azurerm_virtual_network_gateway_connection" "aws" {
  count               = var.deployment_mode == "replica-only" && var.aws_vpn_gateway_ip != "" ? 1 : 0
  name                = "vpnconn-to-aws-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[0].id

  shared_key = var.vpn_shared_key

  tags = merge(var.tags, {
    environment = var.environment
  })
}
