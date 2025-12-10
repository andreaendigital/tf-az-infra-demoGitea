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

output "database_name" {
  description = "Name of the Gitea database"
  value       = azurerm_mysql_flexible_database.gitea.name
}

output "admin_username" {
  description = "Administrator username"
  value       = var.admin_username
  sensitive   = true
}

output "connection_string" {
  description = "MySQL connection string for Gitea"
  value       = "${azurerm_mysql_flexible_server.main.fqdn}:3306"
  sensitive   = true
}
