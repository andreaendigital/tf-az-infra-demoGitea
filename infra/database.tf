# ====================================
# Database - Azure MySQL Flexible Server
# ====================================

# Azure MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-${var.project_name}-${var.environment}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  
  sku_name   = var.mysql_sku_name
  version    = var.mysql_version
  
  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = var.mysql_geo_redundant_backup
  
  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  storage {
    size_gb = var.mysql_storage_size_gb
    iops    = var.mysql_storage_iops
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]

  tags = merge(var.tags, {
    environment = var.environment
    component   = "database"
  })
}

# Private DNS Zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.project_name}-${var.environment}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "mysql-vnet-link-${var.environment}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  
  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Create Gitea database
resource "azurerm_mysql_flexible_database" "gitea" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# MySQL Configuration for replication (when enabled)
resource "azurerm_mysql_flexible_server_configuration" "binlog_enabled" {
  count               = var.enable_replication ? 1 : 0
  name                = "binlog_expire_logs_seconds"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  value               = "86400"  # 1 day
}

resource "azurerm_mysql_flexible_server_configuration" "binlog_format" {
  count               = var.enable_replication ? 1 : 0
  name                = "binlog_format"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  value               = "ROW"
}

# Firewall rule to allow Azure services (optional for replication setup)
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  count               = var.mysql_allow_azure_services ? 1 : 0
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
