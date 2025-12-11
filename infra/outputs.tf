# ====================================
# Resource Group Outputs
# ====================================

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.resource_group.location
}

# ====================================
# Networking Outputs
# ====================================

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_app_id" {
  description = "ID of the application subnet"
  value       = module.networking.subnet_app_id
}

output "subnet_database_id" {
  description = "ID of the database subnet"
  value       = module.networking.subnet_database_id
}

output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway (if enabled)"
  value       = module.networking.vpn_gateway_public_ip
}

# ====================================
# Database Outputs
# ====================================

output "mysql_server_fqdn" {
  description = "Fully qualified domain name of the MySQL server"
  value       = module.database.server_fqdn
  sensitive   = true
}

output "mysql_database_name" {
  description = "Name of the Gitea database"
  value       = module.database.database_name
}

output "mysql_admin_username" {
  description = "MySQL administrator username"
  value       = module.database.admin_username
  sensitive   = true
}

# ====================================
# Load Balancer Outputs
# ====================================

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = module.load_balancer.public_ip_address
}

output "gitea_url" {
  description = "URL to access Gitea application"
  value       = "http://${module.load_balancer.public_ip_address}"
}

# ====================================
# Compute Outputs
# ====================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = module.compute.vm_id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.compute.vm_name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = module.compute.vm_private_ip
}

output "vm_public_ip" {
  description = "Public IP address of the VM (for SSH/Ansible access)"
  value       = module.compute.vm_public_ip
}

output "ssh_connection_string" {
  description = "SSH command to connect directly to the VM"
  value       = "ssh ${var.vm_admin_username}@${module.compute.vm_public_ip}"
}

# ====================================
# Ansible Inventory Output
# ====================================

output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    vm_private_ip = module.compute.vm_private_ip
    vm_public_ip  = module.load_balancer.public_ip_address
    ssh_user      = var.vm_admin_username
    mysql_host    = module.database.server_fqdn
    mysql_db      = module.database.database_name
    mysql_user    = module.database.admin_username
  }
  sensitive = true
}
