# Database Module Outputs

output "server_id" {
  description = "ID of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.main.id
}

output "server_name" {
  description = "Name of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.main.name
}

output "server_fqdn" {
  description = "Fully qualified domain name of the MySQL server"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "server_host" {
  description = "Hostname of the MySQL server (without domain)"
  value       = azurerm_mysql_flexible_server.main.name
}

output "database_name" {
  description = "Name of the Gitea database"
  value       = azurerm_mysql_flexible_database.gitea.name
}

output "admin_username" {
  description = "MySQL administrator username"
  value       = var.admin_username
}

output "admin_password" {
  description = "MySQL administrator password (sensitive)"
  value       = var.admin_password
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = azurerm_private_dns_zone.mysql.id
}
