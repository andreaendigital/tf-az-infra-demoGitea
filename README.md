# Gitea Infrastructure on Azure - Terraform

Terraform Infrastructure as Code (IaC) for deploying Gitea on Microsoft Azure with high availability, MySQL Flexible Server database, and optional VPN connectivity to AWS for failover scenarios.

## 🏗️ Architecture Overview

This repository provisions a complete Azure infrastructure for hosting Gitea with the following components:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Cloud (East US)                        │
│                     VNet 10.1.0.0/16                            │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Load Balancer (Public IP)                    │  │
│  │                   Port 80 → 3000                          │  │
│  └───────────────────────┬──────────────────────────────────┘  │
│                          │                                      │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │            Application Subnet (10.1.2.0/24)              │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  VM Ubuntu 20.04 (Standard_B2s)                    │  │  │
│  │  │  • Gitea Application (Port 3000)                   │  │  │
│  │  │  • Systemd Service Management                      │  │  │
│  │  │  • Static Public IP (for SSH/Ansible)              │  │  │
│  │  │  • Cloud-init for initial setup                    │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │           Database Subnet (10.1.1.0/24)                  │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  MySQL Flexible Server (B_Standard_B1ms)           │  │  │
│  │  │  • MySQL 8.0.21                                    │  │  │
│  │  │  • 20 GB Storage (365 IOPS)                        │  │  │
│  │  │  • 7 days backup retention                         │  │  │
│  │  │  • Geo-redundant backup                            │  │  │
│  │  │  • Private endpoint (VNet integrated)              │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │        Gateway Subnet (10.1.255.0/27) [Optional]         │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  VPN Gateway (VpnGw1)                              │  │  │
│  │  │  • Site-to-Site IPsec connection to AWS           │  │  │
│  │  │  • Enables database replication                   │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
└──────────────────────────┼──────────────────────────────────────┘
                           │ VPN Tunnel (IPsec)
                           ▼
                    ┌──────────────┐
                    │  AWS VPC     │
                    │  10.0.0.0/16 │
                    └──────────────┘
```

## 📋 Features

- ✅ **Modular Terraform Architecture**: Clean separation of concerns with reusable modules
- ✅ **High Availability**: Load balancer distributes traffic to VM instances
- ✅ **Secure Networking**: Private subnets, NSGs, and VNet integration
- ✅ **Static Public IP**: Stable IP for SSH access and Ansible automation
- ✅ **MySQL Flexible Server**: Managed database with automated backups
- ✅ **VPN Gateway Support**: Optional site-to-site connection to AWS
- ✅ **Database Replication**: MySQL master-replica setup for failover (with AWS)
- ✅ **Team SSH Access**: Support for multiple allowed IP addresses
- ✅ **Remote State**: Azure Storage backend for Terraform state
- ✅ **CI/CD Ready**: Jenkins pipeline included for automated deployment
- ✅ **Failover Mode**: Deploy only application infrastructure when database exists

## 🗂️ Project Structure

```
TF-AZ-INFRA-DEMOGITEA/
├── infra/                          # Main Terraform configuration
│   ├── main.tf                     # Module orchestration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── provider.tf                 # Azure provider configuration
│   ├── remote_backend_azurerm.tf   # Remote state configuration
│   └── terraform.tfvars.example    # Example variable values
│
├── modules/                        # Reusable Terraform modules
│   ├── resource-group/             # Azure Resource Group
│   │   └── main.tf
│   │
│   ├── networking/                 # VNet, Subnets, NSG, VPN Gateway
│   │   ├── main.tf
│   │   └── outputs.tf
│   │
│   ├── database/                   # MySQL Flexible Server
│   │   ├── main.tf
│   │   └── outputs.tf
│   │
│   ├── compute/                    # Virtual Machine
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── cloud-init.yaml         # VM initialization script
│   │
│   └── load-balancer/              # Azure Load Balancer
│       ├── main.tf
│       └── outputs.tf
│
├── ansible/                        # Ansible inventory template
│   ├── inventory.ini               # Static inventory with placeholders
│   └── playbook.yml                # Reference to ansible-az-demoGitea repo
│
├── Jenkinsfile                     # CI/CD pipeline for automated deployment
├── JENKINS_SETUP.md                # Jenkins configuration guide
├── README.md                       # This file
└── REPOSITORY_RELATIONSHIPS.md     # Multi-cloud architecture documentation

```

## 🚀 Quick Start

### Prerequisites

| Tool          | Version   | Purpose                                  |
| ------------- | --------- | ---------------------------------------- |
| **Terraform** | >= 1.0    | Infrastructure provisioning              |
| **Azure CLI** | >= 2.40   | Azure authentication                     |
| **SSH Key**   | RSA 2048+ | VM access                                |
| **Ansible**   | >= 2.9    | Configuration management (separate repo) |

### Azure Setup

1. **Install Azure CLI** (if not already installed):

   ```bash
   # macOS
   brew install azure-cli

   # Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Windows
   # Download from: https://aka.ms/installazurecliwindows
   ```

2. **Login to Azure**:

   ```bash
   az login
   ```

3. **Set subscription** (if you have multiple):

   ```bash
   az account list --output table
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   ```

4. **Create SSH key pair** (if you don't have one):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure-gitea-key -C "gitea-azure-vm"
   ```

### Deployment Steps

#### Option A: Manual Deployment (Terraform + Ansible)

For detailed manual deployment steps, continue reading below.

#### Option B: Automated Deployment (Jenkins Pipeline) ⭐ Recommended

Use the included Jenkins pipeline for automated deployment:

```bash
# See JENKINS_SETUP.md for complete Jenkins configuration guide
```

**Jenkins Pipeline Features:**

- ✅ Automated Terraform init/plan/apply
- ✅ Auto-generated Ansible inventory from Terraform outputs
- ✅ FAILOVER mode (deploy only app when DB exists)
- ✅ FULL_STACK mode (deploy everything)
- ✅ Discord notifications on success/failure
- ✅ Built-in verification and health checks

📚 **Full Guide**: [JENKINS_SETUP.md](./JENKINS_SETUP.md)

---

#### Manual Deployment Steps

#### Step 1: Clone Repository

```bash
git clone https://github.com/andreaendigital/tf-az-infra-demoGitea.git
cd tf-az-infra-demoGitea/infra
```

#### Step 2: Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Minimum required configuration:**

```hcl
# terraform.tfvars

project_name = "gitea-infra"
environment  = "demo"
location     = "East US"

# SSH Access - Add your public IP (get it with: curl ifconfig.me)
allowed_ssh_ips = ["YOUR_PUBLIC_IP/32"]

# MySQL Admin Password (CHANGE THIS!)
mysql_admin_password = "YourSecurePassword123!"

# SSH Public Key
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EA... your-public-key"
```

#### Step 3: Initialize Terraform

```bash
terraform init
```

#### Step 4: Preview Changes

```bash
terraform plan
```

#### Step 5: Deploy Infrastructure

```bash
terraform apply
```

When prompted, type `yes` to confirm.

⏱️ **Deployment time:** ~15-20 minutes (VPN Gateway adds ~30 minutes if enabled)

#### Step 6: Get Outputs

```bash
# SSH connection string
terraform output ssh_connection_string

# Gitea URL (via Load Balancer)
terraform output gitea_url

# VM Public IP (for Ansible)
terraform output vm_public_ip

# MySQL connection details
terraform output mysql_server_host
terraform output mysql_database_name
terraform output mysql_admin_username
```

#### Step 7: Configure Ansible Inventory

Update the inventory file for Ansible deployment:

```bash
# In the ansible-az-demoGitea repository
cd ../ansible-az-demoGitea

# Edit inventory.ini with Terraform outputs
nano inventory.ini
```

Replace placeholders with actual values from `terraform output`.

#### Step 8: Deploy Gitea Application

```bash
# From ansible-az-demoGitea repository
ansible-playbook -i inventory.ini playbook.yml
```

See [ansible-az-demoGitea](https://github.com/andreaendigital/ansible-az-demoGitea) for Ansible details.

## 🔧 Configuration

### Core Variables

| Variable               | Description           | Default       | Required |
| ---------------------- | --------------------- | ------------- | -------- |
| `project_name`         | Project identifier    | `gitea-infra` | ✅       |
| `environment`          | Environment name      | `demo`        | ✅       |
| `location`             | Azure region          | `East US`     | ✅       |
| `allowed_ssh_ips`      | IPs allowed to SSH    | `[]`          | ✅       |
| `mysql_admin_password` | MySQL admin password  | -             | ✅       |
| `ssh_public_key`       | SSH public key for VM | -             | ✅       |

### Networking Variables

| Variable                         | Description        | Default         |
| -------------------------------- | ------------------ | --------------- |
| `vnet_address_space`             | VNet CIDR block    | `10.1.0.0/16`   |
| `subnet_app_address_prefix`      | Application subnet | `10.1.2.0/24`   |
| `subnet_database_address_prefix` | Database subnet    | `10.1.1.0/24`   |
| `subnet_gateway_address_prefix`  | VPN Gateway subnet | `10.1.255.0/27` |

### VM Configuration

| Variable            | Description       | Default        |
| ------------------- | ----------------- | -------------- |
| `vm_size`           | Azure VM size     | `Standard_B2s` |
| `vm_admin_username` | VM admin username | `azureuser`    |

### Database Configuration

| Variable                      | Description      | Default           |
| ----------------------------- | ---------------- | ----------------- |
| `mysql_admin_username`        | MySQL admin user | `gitea_admin`     |
| `mysql_sku_name`              | MySQL tier       | `B_Standard_B1ms` |
| `mysql_version`               | MySQL version    | `8.0.21`          |
| `mysql_storage_size_gb`       | Storage size     | `20`              |
| `mysql_backup_retention_days` | Backup retention | `7`               |

### VPN Gateway (Optional)

For AWS connectivity and database replication:

| Variable             | Description        | Required for VPN |
| -------------------- | ------------------ | ---------------- |
| `enable_vpn_gateway` | Enable VPN Gateway | ✅               |
| `aws_vpn_gateway_ip` | AWS VPN public IP  | ✅               |
| `aws_vpc_cidr`       | AWS VPC CIDR       | ✅               |
| `vpn_shared_key`     | IPsec shared key   | ✅               |

**Enable VPN in terraform.tfvars:**

```hcl
enable_vpn_gateway = true
aws_vpn_gateway_ip = "54.123.45.67"  # From AWS terraform output
aws_vpc_cidr       = "10.0.0.0/16"
vpn_shared_key     = "YourSecureVPNKey123!"
```

## 📤 Terraform Outputs

All outputs are available for integration with Ansible and CI/CD:

```bash
# Resource Group
terraform output resource_group_name
terraform output resource_group_location

# Networking
terraform output vnet_id
terraform output vpn_gateway_public_ip  # For AWS configuration

# Compute
terraform output vm_public_ip
terraform output vm_private_ip
terraform output ssh_connection_string

# Database
terraform output mysql_server_host
terraform output mysql_database_name
terraform output mysql_admin_username

# Load Balancer
terraform output load_balancer_public_ip
terraform output gitea_url

# Ansible Helper
terraform output ansible_inventory  # Structured output for automation
```

## 🔐 Security Best Practices

### 1. SSH Access Control

**Always restrict SSH to known IPs:**

```hcl
# ✅ Good: Single IP
allowed_ssh_ips = ["203.0.113.45/32"]

# ✅ Good: Team access
allowed_ssh_ips = [
  "203.0.113.45/32",    # John
  "198.51.100.10/32",   # Jane
  "192.0.2.5/32"        # CI/CD server
]

# ❌ Bad: Open to Internet
allowed_ssh_ips = ["0.0.0.0/0"]
```

### 2. Sensitive Variables

Use environment variables or Jenkins credentials for secrets:

```bash
export TF_VAR_mysql_admin_password="SecurePassword123!"
export TF_VAR_vpn_shared_key="VPNSharedKey456!"
terraform apply
```

### 3. State File Security

The Terraform state is stored in Azure Storage with encryption:

```hcl
# remote_backend_azurerm.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "gitea-infra.tfstate"
  }
}
```

**Never commit state files to Git!**

### 4. MySQL Password Management

- Use Azure Key Vault for production
- Rotate passwords regularly
- Never hardcode in `.tf` files
- Use Jenkins credentials for CI/CD

## 🔄 Database Replication (AWS ↔ Azure)

This infrastructure supports MySQL replication from AWS RDS (master) to Azure MySQL Flexible Server (replica).

### Prerequisites

1. Deploy AWS infrastructure first: [tf-infra-demoGitea](https://github.com/andreaendigital/tf-infra-demoGitea)
2. Enable VPN Gateway on both sides
3. Configure replication settings

### Replication Setup

See [REPLICATION_SETUP.md](https://github.com/andreaendigital/tf-infra-demoGitea/blob/main/REPLICATION_SETUP.md) in the AWS repository for detailed instructions.

**Quick overview:**

```hcl
# terraform.tfvars
enable_replication    = true
aws_rds_endpoint      = "mydb.abc123.us-east-1.rds.amazonaws.com"
replication_user      = "repl_azure"
replication_password  = "SecureReplPassword!"
```

## 🗑️ Cleanup

To destroy all resources:

```bash
cd infra
terraform destroy
```

**⚠️ Warning:** This will permanently delete:

- Virtual Machines
- Databases (and all data)
- Load Balancers
- VPN Gateways
- All networking resources

Backups are retained according to your backup retention policy (default: 7 days).

## 🔗 Related Repositories

| Repository               | Purpose                              | Link                                                              |
| ------------------------ | ------------------------------------ | ----------------------------------------------------------------- |
| **ansible-az-demoGitea** | Ansible playbooks for Gitea on Azure | [GitHub](https://github.com/andreaendigital/ansible-az-demoGitea) |
| **tf-infra-demoGitea**   | Terraform for AWS infrastructure     | [GitHub](https://github.com/andreaendigital/tf-infra-demoGitea)   |
| **ansible-demoGitea**    | Ansible playbooks for Gitea on AWS   | [GitHub](https://github.com/andreaendigital/ansible-demoGitea)    |

See [REPOSITORY_RELATIONSHIPS.md](./REPOSITORY_RELATIONSHIPS.md) for complete architecture overview.

## 📊 Cost Estimation

Approximate monthly costs (Pay-as-you-go, East US):

| Resource                | SKU               | Estimated Cost      |
| ----------------------- | ----------------- | ------------------- |
| VM                      | Standard_B2s      | $30-40/month        |
| MySQL Flexible Server   | B_Standard_B1ms   | $15-25/month        |
| Load Balancer           | Basic             | $18/month           |
| Public IPs              | 2 static IPs      | $8/month            |
| VPN Gateway             | VpnGw1 (optional) | $140/month          |
| Storage/Bandwidth       | Varies            | $5-10/month         |
| **Total (without VPN)** |                   | **~$75-100/month**  |
| **Total (with VPN)**    |                   | **~$215-250/month** |

💡 **Cost optimization tips:**

- Use B-series burstable VMs for dev/test
- Enable auto-shutdown for non-production VMs
- Use spot instances where applicable
- Disable VPN Gateway when not needed

## 🐛 Troubleshooting

### Issue: SSH connection refused

**Solution:**

```bash
# Verify your IP is allowed
curl ifconfig.me

# Add your IP to allowed_ssh_ips in terraform.tfvars and re-apply
terraform apply
```

### Issue: MySQL connection error from VM

**Solution:**

```bash
# Check NSG rules allow VM → MySQL
terraform output | grep mysql

# Verify private DNS zone is configured
az network private-dns zone list -o table
```

### Issue: VPN tunnel not connecting

**Solution:**

```bash
# Verify shared key matches on both sides
# Check BGP settings
# Ensure gateway subnet is correct size (/27 minimum)

az network vnet-gateway list -o table
```

### Issue: Terraform state locked

**Solution:**

```bash
# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

## 📚 Additional Documentation

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure MySQL Flexible Server](https://learn.microsoft.com/en-us/azure/mysql/flexible-server/)
- [Azure VPN Gateway](https://learn.microsoft.com/en-us/azure/vpn-gateway/)
- [Gitea Official Documentation](https://docs.gitea.com/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 👤 Author

**Andrea Beltrán**

- GitHub: [@andreaendigital](https://github.com/andreaendigital)

## 🙏 Acknowledgments

- Terraform Azure Provider team
- Gitea community
- DevOps best practices contributors
