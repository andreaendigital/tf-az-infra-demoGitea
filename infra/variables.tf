# ====================================
# General Variables
# ====================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "gitea-infra"
}

variable "environment" {
  description = "Environment name (dev, demo, prod)"
  type        = string
  default     = "demo"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West US 2"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    project     = "gitea-infra"
    team        = "devops"
    cost-center = "it-001"
    managed-by  = "terraform"
  }
}

# ====================================
# Networking Variables
# ====================================

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_app_address_prefix" {
  description = "Address prefix for application subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "subnet_database_address_prefix" {
  description = "Address prefix for database subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "subnet_gateway_address_prefix" {
  description = "Address prefix for VPN gateway subnet"
  type        = string
  default     = "10.1.3.0/24"
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed for SSH access. Leave empty to use admin_source_ip"
  type        = list(string)
  default     = []
}

variable "admin_source_ip" {
  description = "Source IP address for SSH access (your IP). Leave empty for any"
  type        = string
  default     = ""
}

# ====================================
# VPN Gateway Variables (for AWS connection)
# ====================================

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for site-to-site connection with AWS"
  type        = bool
  default     = false
}

variable "aws_vpn_gateway_ip" {
  description = "Public IP address of AWS VPN Gateway"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "CIDR block of AWS VPC for VPN connection"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpn_shared_key" {
  description = "Shared key for VPN connection (IPsec)"
  type        = string
  sensitive   = true
  default     = ""
}

# ====================================
# MySQL Database Variables
# ====================================

variable "mysql_admin_username" {
  description = "Administrator username for MySQL"
  type        = string
  sensitive   = true
  default     = "gitea_admin"
}

variable "mysql_admin_password" {
  description = "Administrator password for MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_sku_name" {
  description = "SKU name for MySQL Flexible Server (e.g., B_Standard_B1ms)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0.21"
}

variable "mysql_storage_size_gb" {
  description = "Storage size in GB for MySQL"
  type        = number
  default     = 20
}

variable "mysql_storage_iops" {
  description = "Storage IOPS for MySQL"
  type        = number
  default     = 360
}

variable "mysql_backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "mysql_geo_redundant_backup" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "mysql_database_name" {
  description = "Name of the Gitea database"
  type        = string
  default     = "infraGiteaDB"
}

variable "mysql_allow_azure_services" {
  description = "Allow Azure services to access the database"
  type        = bool
  default     = false
}

# ====================================
# MySQL Replication Variables (AWS RDS)
# ====================================

variable "enable_replication" {
  description = "Enable replication from AWS RDS"
  type        = bool
  default     = false
}

variable "aws_rds_endpoint" {
  description = "AWS RDS endpoint for replication (without port)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "replication_user" {
  description = "MySQL replication username on AWS RDS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "replication_password" {
  description = "MySQL replication password on AWS RDS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "master_log_file" {
  description = "MySQL binary log file name from AWS RDS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "master_log_pos" {
  description = "MySQL binary log position from AWS RDS"
  type        = number
  default     = 0
}

# ====================================
# Compute (VM) Variables
# ====================================

variable "vm_size" {
  description = "Size of the VM (e.g., Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
