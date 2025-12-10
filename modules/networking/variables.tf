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
  default     = "10.1.255.0/27"
}

variable "admin_source_ip" {
  description = "Source IP address for SSH access (your IP). Leave empty for any"
  type        = string
  default     = ""
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for site-to-site connection with AWS"
  type        = bool
  default     = false
}

variable "aws_vpn_gateway_ip" {
  description = "Public IP address of AWS VPN Gateway"
  type        = string
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "CIDR block of AWS VPC for VPN connection"
  type        = string
  default     = ""
}

variable "vpn_shared_key" {
  description = "Shared key for VPN connection (IPsec)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
