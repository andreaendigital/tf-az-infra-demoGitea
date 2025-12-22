resource "azurerm_public_ip" "lb" {
  count               = var.deployment_mode != "replica-only" ? 1 : 0
  name                = "pip-lb-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    environment = var.environment
    component   = "load-balancer"
  })
}

resource "azurerm_lb" "main" {
  count               = var.deployment_mode != "replica-only" ? 1 : 0
  name                = "lb-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb[0].id
  }

  tags = merge(var.tags, {
    environment = var.environment
    component   = "load-balancer"
  })
}

resource "azurerm_lb_backend_address_pool" "main" {
  count           = var.deployment_mode != "replica-only" ? 1 : 0
  loadbalancer_id = azurerm_lb.main[0].id
  name            = "GiteaBackendPool"
}

resource "azurerm_lb_probe" "gitea" {
  count           = var.deployment_mode != "replica-only" ? 1 : 0
  loadbalancer_id = azurerm_lb.main[0].id
  name            = "gitea-health-probe"
  protocol        = "Http"
  port            = 3000
  request_path    = "/"
}

resource "azurerm_lb_rule" "http" {
  count                          = var.deployment_mode != "replica-only" ? 1 : 0
  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 3000
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  probe_id                       = azurerm_lb_probe.gitea[0].id
  disable_outbound_snat          = false
}

resource "azurerm_lb_rule" "ssh" {
  count                          = var.deployment_mode != "replica-only" ? 1 : 0
  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "SSHRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  disable_outbound_snat          = false
}
