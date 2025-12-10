# Resource Group Module
module "resource_group" {
  source = "../modules/resource-group"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  tags         = var.tags
}

# Networking Module (VNet + Subnets + NSG + VPN Gateway)
module "networking" {
  source = "../modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name

  vnet_address_space              = var.vnet_address_space
  subnet_app_address_prefix       = var.subnet_app_address_prefix
  subnet_database_address_prefix  = var.subnet_database_address_prefix
  subnet_gateway_address_prefix   = var.subnet_gateway_address_prefix
  admin_source_ip                 = var.admin_source_ip

  enable_vpn_gateway   = var.enable_vpn_gateway
  aws_vpn_gateway_ip   = var.aws_vpn_gateway_ip
  aws_vpc_cidr         = var.aws_vpc_cidr
  vpn_shared_key       = var.vpn_shared_key

  tags = var.tags
}

# Database Module (Azure MySQL Flexible Server)
module "database" {
  source = "../modules/database"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  
  subnet_id = module.networking.subnet_database_id
  vnet_id   = module.networking.vnet_id

  admin_username               = var.mysql_admin_username
  admin_password               = var.mysql_admin_password
  sku_name                     = var.mysql_sku_name
  mysql_version                = var.mysql_version
  storage_size_gb              = var.mysql_storage_size_gb
  storage_iops                 = var.mysql_storage_iops
  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = var.mysql_geo_redundant_backup
  database_name                = var.mysql_database_name
  allow_azure_services         = var.mysql_allow_azure_services

  # Replication configuration (disabled by default)
  enable_replication     = var.enable_replication
  aws_rds_endpoint       = var.aws_rds_endpoint
  replication_user       = var.replication_user
  replication_password   = var.replication_password
  master_log_file        = var.master_log_file
  master_log_pos         = var.master_log_pos

  tags = var.tags
}

# Load Balancer Module
module "load_balancer" {
  source = "../modules/load-balancer"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name

  tags = var.tags
}

# Compute Module (Linux VM for Gitea)
module "compute" {
  source = "../modules/compute"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name

  subnet_id           = module.networking.subnet_app_id
  lb_backend_pool_id  = module.load_balancer.backend_pool_id
  
  vm_size          = var.vm_size
  admin_username   = var.vm_admin_username
  ssh_public_key   = var.ssh_public_key

  tags = var.tags
}
