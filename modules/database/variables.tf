variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, demo, prod)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for MySQL Flexible Server"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for MySQL"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for MySQL"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name for MySQL Flexible Server (e.g., B_Standard_B1ms)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0.21"
}

variable "storage_size_gb" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "storage_iops" {
  description = "Storage IOPS"
  type        = number
  default     = 360
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the Gitea database"
  type        = string
  default     = "infraGiteaDB"
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the database"
  type        = bool
  default     = false
}

# Replication variables (for future AWS RDS replication)
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

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
