# ====================================
# Resource Group Outputs
# ====================================

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# ====================================
# Networking Outputs
# ====================================

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

output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway (if enabled)"
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
}

# ====================================
# Database Outputs
# ====================================

output "mysql_server_fqdn" {
  description = "Fully qualified domain name of the MySQL server"
  value       = azurerm_mysql_flexible_server.main.fqdn
  sensitive   = true
}

output "mysql_server_host" {
  description = "Hostname of the MySQL server (for Ansible mysql_host variable)"
  value       = azurerm_mysql_flexible_server.main.fqdn
  sensitive   = true
}

output "mysql_database_name" {
  description = "Name of the Gitea database"
  value       = azurerm_mysql_flexible_database.gitea.name
}

output "mysql_admin_username" {
  description = "MySQL administrator username"
  value       = azurerm_mysql_flexible_server.main.administrator_login
  sensitive   = true
}

output "mysql_admin_password" {
  description = "MySQL administrator password (from Jenkins credentials)"
  value       = var.mysql_admin_password
  sensitive   = true
}

# ====================================
# Load Balancer Outputs
# ====================================

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.lb_public_ip.ip_address
}

output "gitea_url" {
  description = "URL to access Gitea application"
  value       = "http://${azurerm_public_ip.lb_public_ip.ip_address}"
}

# ====================================
# Compute Outputs
# ====================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the VM (for SSH/Ansible access)"
  value       = azurerm_public_ip.vm_public_ip.ip_address
}

output "ssh_connection_string" {
  description = "SSH command to connect directly to the VM"
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.vm_public_ip.ip_address}"
}

# ====================================
# Ansible Inventory Output
# ====================================

output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    vm_private_ip = azurerm_network_interface.main.private_ip_address
    vm_public_ip  = azurerm_public_ip.lb_public_ip.ip_address
    ssh_user      = var.vm_admin_username
    mysql_host    = azurerm_mysql_flexible_server.main.fqdn
    mysql_db      = azurerm_mysql_flexible_database.gitea.name
    mysql_user    = azurerm_mysql_flexible_server.main.administrator_login
  }
  sensitive = true
}
