# Azure MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-${var.project_name}-${var.environment}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  
  sku_name   = var.sku_name
  version    = var.mysql_version
  
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  storage {
    size_gb = var.storage_size_gb
    iops    = var.storage_iops
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]

  tags = merge(var.tags, {
    environment = var.environment
    module      = "database"
  })
}

# Private DNS Zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.project_name}-${var.environment}.mysql.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "mysql-vnet-link-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  
  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Create Gitea database
resource "azurerm_mysql_flexible_database" "gitea" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# MySQL Configuration for replication (when enabled)
resource "azurerm_mysql_flexible_server_configuration" "binlog_enabled" {
  count               = var.enable_replication ? 1 : 0
  name                = "binlog_expire_logs_seconds"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  value               = "86400"  # 1 day
}

resource "azurerm_mysql_flexible_server_configuration" "binlog_format" {
  count               = var.enable_replication ? 1 : 0
  name                = "binlog_format"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  value               = "ROW"
}

# Firewall rule to allow Azure services (optional for replication setup)
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  count               = var.allow_azure_services ? 1 : 0
  name                = "AllowAzureServices"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Configure replication from AWS RDS (disabled by default)
# Uncomment and configure when AWS RDS is ready for replication
/*
resource "null_resource" "configure_replication" {
  count = var.enable_replication && var.aws_rds_endpoint != "" ? 1 : 0
  
  depends_on = [
    azurerm_mysql_flexible_server.main,
    azurerm_mysql_flexible_database.gitea
  ]

  provisioner "local-exec" {
    command = <<-EOT
      mysql -h ${azurerm_mysql_flexible_server.main.fqdn} \
            -u ${var.admin_username} \
            -p'${var.admin_password}' \
            -e "
              STOP SLAVE;
              CHANGE MASTER TO
                MASTER_HOST='${var.aws_rds_endpoint}',
                MASTER_USER='${var.replication_user}',
                MASTER_PASSWORD='${var.replication_password}',
                MASTER_PORT=3306,
                MASTER_LOG_FILE='${var.master_log_file}',
                MASTER_LOG_POS=${var.master_log_pos},
                MASTER_SSL=1;
              START SLAVE;
              SHOW SLAVE STATUS\G
            "
    EOT

    environment = {
      MYSQL_PWD = var.admin_password
    }
  }

  triggers = {
    replication_config = md5(join("", [
      var.aws_rds_endpoint,
      var.replication_user,
      var.master_log_file,
      tostring(var.master_log_pos)
    ]))
  }
}
*/
