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
  description = "Public IP of the VPN Gateway (replica-only mode)"
  value       = var.deployment_mode == "replica-only" ? azurerm_public_ip.vpn_gateway[0].ip_address : null
}

output "mysql_vm_id" {
  description = "ID of the MySQL VM"
  value       = azurerm_linux_virtual_machine.mysql.id
}

output "mysql_vm_name" {
  description = "Name of the MySQL VM"
  value       = azurerm_linux_virtual_machine.mysql.name
}

output "mysql_vm_private_ip" {
  description = "Private IP address of the MySQL VM (access via jump host through Gitea VM)"
  value       = azurerm_network_interface.mysql.private_ip_address
}

output "mysql_vm_public_ip" {
  description = "Public IP address of the MySQL VM (replica-only mode only, for Ansible setup)"
  value       = var.deployment_mode == "replica-only" ? azurerm_public_ip.mysql[0].ip_address : null
}

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? azurerm_public_ip.lb[0].ip_address : null
}

output "gitea_url" {
  description = "URL to access Gitea application (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? "http://${azurerm_public_ip.lb[0].ip_address}" : null
}

output "vm_id" {
  description = "ID of the virtual machine (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? azurerm_linux_virtual_machine.main[0].id : null
}

output "vm_name" {
  description = "Name of the virtual machine (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? azurerm_linux_virtual_machine.main[0].name : null
}

output "vm_private_ip" {
  description = "Private IP address of the VM (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? azurerm_network_interface.main[0].private_ip_address : null
}

output "vm_public_ip" {
  description = "Public IP address of the VM for SSH/Ansible (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? azurerm_public_ip.vm[0].ip_address : null
}

output "ssh_connection_string" {
  description = "SSH command to connect directly to the VM (full-stack and failover)"
  value       = var.deployment_mode != "replica-only" ? "ssh ${var.vm_admin_username}@${azurerm_public_ip.vm[0].ip_address}" : null
}

# ====================================
# Ansible Inventory Output
# ====================================

output "ansible_inventory" {
  description = "Ansible inventory information (MySQL accessed via jump host)"
  value = var.deployment_mode != "replica-only" ? {
    vm_private_ip        = azurerm_network_interface.main[0].private_ip_address
    vm_public_ip         = azurerm_public_ip.vm[0].ip_address
    mysql_vm_private_ip  = azurerm_network_interface.mysql.private_ip_address
    ssh_user             = var.vm_admin_username
    deployment_mode      = var.deployment_mode
  } : {
    mysql_vm_private_ip  = azurerm_network_interface.mysql.private_ip_address
    ssh_user             = var.vm_admin_username
    deployment_mode      = var.deployment_mode
  }
  sensitive = true
}
