# Jenkins Pipeline Setup for Azure Gitea

This guide explains how to configure and use the Jenkins pipeline for deploying Gitea infrastructure on Azure.

## 🎯 Pipeline Purpose

This Jenkinsfile automates the deployment of Gitea on Azure, supporting two scenarios:

1. **FAILOVER Mode**: Deploy only application infrastructure (VM + LB), assuming MySQL database already exists and is replicating from AWS
2. **FULL_STACK Mode**: Deploy complete infrastructure including database

## 📋 Prerequisites

### 1. Jenkins Plugins Required

Install these plugins in Jenkins:

- **Azure Credentials Plugin** - For Azure authentication
- **SSH Agent Plugin** - For Ansible SSH connections
- **Pipeline Plugin** - For pipeline support
- **Git Plugin** - For repository cloning
- **Credentials Binding Plugin** - For secure credential handling

### 2. Azure Service Principal

Create an Azure Service Principal for Terraform:

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "jenkins-terraform-sp" \
    --role="Contributor" \
    --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Output will show:
# {
#   "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",       # ARM_CLIENT_ID
#   "displayName": "jenkins-terraform-sp",
#   "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",   # ARM_CLIENT_SECRET
#   "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"      # ARM_TENANT_ID
# }
```

### 3. SSH Key Pair

Generate SSH key pair for Azure VM access:

```bash
# Generate key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure-gitea-key -C "jenkins-azure-gitea"

# This creates:
# ~/.ssh/azure-gitea-key       (private key - for Jenkins)
# ~/.ssh/azure-gitea-key.pub   (public key - for Terraform)
```

## 🔐 Jenkins Credentials Setup

Navigate to: **Jenkins → Manage Jenkins → Credentials → Global → Add Credentials**

### Credential 1: Azure Service Principal

| Field | Value |
|-------|-------|
| **Kind** | Azure Service Principal |
| **ID** | `azure-service-principal` |
| **Subscription ID** | Your Azure subscription ID |
| **Client ID** | `appId` from service principal |
| **Client Secret** | `password` from service principal |
| **Tenant ID** | `tenant` from service principal |
| **Description** | Azure Service Principal for Terraform |

### Credential 2: MySQL Admin Password

| Field | Value |
|-------|-------|
| **Kind** | Secret text |
| **ID** | `mysql-admin-password` |
| **Secret** | Your MySQL admin password (e.g., `SecurePassword123!`) |
| **Description** | Azure MySQL admin password |

### Credential 3: Azure SSH Public Key

| Field | Value |
|-------|-------|
| **Kind** | Secret text |
| **ID** | `azure-ssh-public-key` |
| **Secret** | Content of `~/.ssh/azure-gitea-key.pub` |
| **Description** | SSH public key for Azure VM |

### Credential 4: Azure SSH Private Key

| Field | Value |
|-------|-------|
| **Kind** | SSH Username with private key |
| **ID** | `azure-ssh-key` |
| **Username** | `azureuser` |
| **Private Key** | Enter directly → paste content of `~/.ssh/azure-gitea-key` |
| **Passphrase** | (leave empty if no passphrase) |
| **Description** | SSH private key for Ansible |

## 📝 Create Jenkins Pipeline Job

### Step 1: Create New Item

1. Go to Jenkins Dashboard
2. Click **"New Item"**
3. Enter name: `Azure-Gitea-Deployment`
4. Select: **Pipeline**
5. Click **OK**

### Step 2: Configure Pipeline

#### General Section

- ✅ Check **"This project is parameterized"** (automatically handled by Jenkinsfile)
- ✅ Check **"Do not allow concurrent builds"** (recommended)

#### Pipeline Section

| Field | Value |
|-------|-------|
| **Definition** | Pipeline script from SCM |
| **SCM** | Git |
| **Repository URL** | `https://github.com/andreaendigital/tf-az-infra-demoGitea` |
| **Branch** | `DEMO-23-write-terraform-azure-infra-repo` |
| **Script Path** | `Jenkinsfile` |

#### Advanced Options (Optional)

- **Lightweight checkout**: ✅ Enabled (faster)

### Step 3: Save Configuration

Click **Save**

## 🚀 Running the Pipeline

### Scenario 1: Initial Database Deployment (FULL_STACK)

**Use Case**: First time setup, deploy everything including MySQL database

1. Click **"Build with Parameters"**
2. Configure:
   - **PLAN_TERRAFORM**: ✅ true
   - **APPLY_TERRAFORM**: ✅ true
   - **DEPLOY_ANSIBLE**: ❌ false (deploy app later)
   - **DESTROY_TERRAFORM**: ❌ false
   - **DEPLOYMENT_MODE**: `FULL_STACK`
3. Click **Build**

This will create:
- Resource Group
- VNet + Subnets
- MySQL Flexible Server (ready for replication)
- VPN Gateway (if configured)

### Scenario 2: Failover Deployment (Application Only)

**Use Case**: AWS is down, database already replicating, deploy application now

1. Click **"Build with Parameters"**
2. Configure:
   - **PLAN_TERRAFORM**: ✅ true
   - **APPLY_TERRAFORM**: ✅ true
   - **DEPLOY_ANSIBLE**: ✅ true
   - **DESTROY_TERRAFORM**: ❌ false
   - **DEPLOYMENT_MODE**: `FAILOVER`
3. Click **Build**

This will create:
- VM (Standard_B2s)
- Load Balancer
- Install Gitea via Ansible
- Connect to existing MySQL database

### Scenario 3: Destroy Infrastructure

**Use Case**: Cleanup or testing

1. Click **"Build with Parameters"**
2. Configure:
   - **DESTROY_TERRAFORM**: ✅ true
   - All others: ❌ false
3. Click **Build**
4. Confirm destruction when prompted

## 📊 Pipeline Stages Explained

### Stage 1: Preparation
- Displays configuration
- Shows deployment mode

### Stage 2: Clone Repositories
- Clones `tf-az-infra-demoGitea` (Terraform)
- Clones `ansible-az-demoGitea` (Ansible)

### Stage 3: Verify Azure Credentials
- Tests Azure Service Principal authentication
- Validates subscription access

### Stage 4: Terraform Init
- Initializes Terraform backend
- Downloads required providers

### Stage 5: Terraform Plan
- Creates execution plan
- Shows what will be created/changed/destroyed

### Stage 6: Terraform Apply
- Deploys infrastructure
- Outputs resource information

### Stage 7: Extract Terraform Outputs
- Gets VM public IP
- Gets MySQL connection details
- Saves for Ansible use

### Stage 8: Configure Ansible Inventory
- Auto-generates `inventory.ini`
- Populates with Terraform outputs

### Stage 9: Wait for VM to be Ready
- Waits for Azure VM to complete initialization
- Tests SSH connectivity

### Stage 10: Run Ansible Playbook
- Installs Gitea binary
- Configures MySQL connection
- Sets up systemd service
- Starts Gitea

### Stage 11: Verify Gitea Deployment
- Tests Gitea HTTP endpoint
- Confirms application is running

### Stage 12: Terraform Destroy (Optional)
- Destroys all resources
- Requires manual confirmation

## 🔔 Notifications

The pipeline sends Discord notifications on:
- ✅ **Success**: Deployment completed with Gitea URL
- ❌ **Failure**: Error details and build link

Configure webhook URL in Jenkinsfile:
```groovy
environment {
    DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"
}
```

## 🐛 Troubleshooting

### Issue: Azure authentication fails

**Solution:**
```bash
# Verify service principal
az login --service-principal \
    -u <CLIENT_ID> \
    -p <CLIENT_SECRET> \
    --tenant <TENANT_ID>

# Check permissions
az role assignment list --assignee <CLIENT_ID>
```

### Issue: SSH connection to VM fails

**Solution:**
1. Verify SSH key credential ID matches in Jenkinsfile: `azure-ssh-key`
2. Check NSG allows SSH from Jenkins server IP
3. Wait longer for VM initialization (cloud-init takes ~2-3 minutes)

### Issue: Ansible fails to find inventory

**Solution:**
- Inventory is auto-generated in stage "Configure Ansible Inventory"
- Check Terraform outputs are extracted correctly
- Verify `${WORKSPACE}/${INVENTORY_FILE}` path is correct

### Issue: Gitea doesn't start

**Solution:**
```bash
# SSH to Azure VM
ssh azureuser@<VM_PUBLIC_IP>

# Check Gitea status
sudo systemctl status gitea

# Check logs
sudo journalctl -u gitea -n 50

# Check MySQL connection
mysql -h <MYSQL_HOST> -u <USER> -p
```

### Issue: Terraform state locked

**Solution:**
```bash
# In Jenkins, run shell command:
cd infra
terraform force-unlock <LOCK_ID>
```

## 📁 File Structure

```
TF-AZ-INFRA-DEMOGITEA/
├── Jenkinsfile                     # ← This pipeline
├── JENKINS_SETUP.md                # ← This documentation
├── README.md                       # General project documentation
├── REPOSITORY_RELATIONSHIPS.md     # Multi-cloud architecture
│
├── infra/                          # Terraform configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── terraform.tfvars           # ← Create this manually
│
└── ansible/                        # Reference only
    └── inventory.ini               # Template (auto-generated by Jenkins)
```

## 🔄 Typical Failover Workflow

### Phase 1: Initial Setup (Do Once)

1. **Deploy Azure Database** (FULL_STACK mode, Ansible=false)
   ```
   Jenkins → Build with Parameters
   Mode: FULL_STACK
   Ansible: false
   ```

2. **Configure VPN** between AWS and Azure (manual, see REPLICATION_SETUP.md)

3. **Setup MySQL Replication** (manual, see REPLICATION_SETUP.md)

### Phase 2: AWS is Running (Normal Operations)

- AWS Gitea serves traffic
- Azure MySQL replicates continuously
- Azure application infrastructure **NOT deployed** (cost savings)

### Phase 3: AWS Fails (Failover)

1. **Detect AWS failure** (monitoring alert)

2. **Deploy Azure Application** (FAILOVER mode)
   ```
   Jenkins → Build with Parameters
   Mode: FAILOVER
   Ansible: true
   ```
   ⏱️ Time: ~15-20 minutes

3. **Promote Azure MySQL** (manual):
   ```sql
   STOP SLAVE;
   RESET SLAVE ALL;
   ```

4. **Verify Gitea** is accessible at `http://<AZURE_LB_IP>`

5. **Update DNS** to point to Azure (if using custom domain)

### Phase 4: AWS Recovery (Optional)

- Reverse replication direction
- Or keep Azure as primary

## 🎓 Best Practices

1. **Test the pipeline** in dev environment first
2. **Run PLAN before APPLY** to review changes
3. **Keep terraform.tfvars secure** (don't commit to Git)
4. **Use semantic versioning** for Terraform modules
5. **Document all manual steps** for failover
6. **Test failover procedure** regularly (quarterly)
7. **Monitor Terraform state** for drift
8. **Set up Azure cost alerts** to avoid surprises

## 📚 Related Documentation

- [README.md](./README.md) - Azure infrastructure overview
- [REPOSITORY_RELATIONSHIPS.md](./REPOSITORY_RELATIONSHIPS.md) - Multi-cloud architecture
- [TF-INFRA-DEMOGITEA/REPLICATION_SETUP.md](https://github.com/andreaendigital/tf-infra-demoGitea/blob/main/REPLICATION_SETUP.md) - MySQL replication guide

## 🆘 Support

For issues or questions:
1. Check Jenkins console output for errors
2. Review Terraform state: `terraform show`
3. Verify Azure resources in portal
4. Check Ansible logs in build output

---

**Last Updated**: December 11, 2025  
**Pipeline Version**: 1.0.0  
**Maintained by**: Andrea Beltrán (@andreaendigital)
