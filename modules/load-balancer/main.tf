# Public IP for Load Balancer
resource "azurerm_public_ip" "main" {
  name                = "pip-lb-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    environment = var.environment
    module      = "load-balancer"
  })
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "lb-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = merge(var.tags, {
    environment = var.environment
    module      = "load-balancer"
  })
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "GiteaBackendPool"
}

# Health Probe for Gitea (port 3000)
resource "azurerm_lb_probe" "gitea" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "gitea-health-probe"
  protocol        = "Http"
  port            = 3000
  request_path    = "/"
}

# Load Balancer Rule for HTTP (80 -> 3000)
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 3000
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.gitea.id
  disable_outbound_snat          = false
}

# Load Balancer Rule for Gitea SSH (22)
resource "azurerm_lb_rule" "ssh" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "SSHRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  disable_outbound_snat          = false
}
