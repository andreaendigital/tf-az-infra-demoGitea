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
/* MySQL Flexible Server outputs removed. MySQL will be provided by a VM; new outputs will be added after VM creation. */

# ====================================
# Load Balancer Outputs
# ====================================

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "gitea_url" {
  description = "URL to access Gitea application"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
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
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_connection_string" {
  description = "SSH command to connect directly to the VM"
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.vm.ip_address}"
}

# ====================================
# Ansible Inventory Output
# ====================================

output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    vm_private_ip = azurerm_network_interface.main.private_ip_address
    vm_public_ip  = azurerm_public_ip.vm.ip_address
    ssh_user      = var.vm_admin_username
  }
  sensitive = true
}
