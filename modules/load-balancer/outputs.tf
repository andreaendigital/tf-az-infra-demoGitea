# Load Balancer Module Outputs

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = azurerm_lb.main.id
}

output "load_balancer_name" {
  description = "Name of the load balancer"
  value       = azurerm_lb.main.name
}

output "public_ip_id" {
  description = "ID of the public IP resource"
  value       = azurerm_public_ip.main.id
}

output "public_ip_address" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.main.ip_address
}

output "backend_pool_id" {
  description = "ID of the backend address pool"
  value       = azurerm_lb_backend_address_pool.main.id
}

output "frontend_ip_configuration" {
  description = "Frontend IP configuration name"
  value       = azurerm_lb.main.frontend_ip_configuration[0].name
}
