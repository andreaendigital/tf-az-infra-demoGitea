output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_app_id" {
  description = "ID of the application subnet"
  value       = azurerm_subnet.app.id
}

output "subnet_database_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "subnet_gateway_id" {
  description = "ID of the gateway subnet"
  value       = azurerm_subnet.gateway.id
}

output "nsg_app_id" {
  description = "ID of the application NSG"
  value       = azurerm_network_security_group.app.id
}

output "nsg_database_id" {
  description = "ID of the database NSG"
  value       = azurerm_network_security_group.database.id
}

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway (if enabled)"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.main[0].id : null
}

output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway (if enabled)"
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
}
