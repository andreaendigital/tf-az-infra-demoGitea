# Terraform Remote Backend Setup

## Overview
This directory contains configuration for Azure Storage backend to persist Terraform state across pipeline executions.

## Why Remote Backend?
- **Prevents state loss** when Jenkins workspace is cleaned
- **Enables team collaboration** with shared state
- **Provides state locking** to prevent concurrent modifications
- **Backs up state automatically** in Azure Storage

## One-Time Setup (Run from Jenkins Server)

### Option 1: Using Azure CLI (Recommended)

```bash
# SSH to Jenkins server
ssh -i ~/.ssh/vm-jenkins_key.pem azureuser@20.51.213.39

# Login to Azure
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# Run setup script
cd /var/lib/jenkins/workspace/GiteaAzure/infra
chmod +x backend-setup.sh
./backend-setup.sh
```

### Option 2: Using Azure Portal

1. Go to https://portal.azure.com
2. Create Resource Group: `rg-terraform-state`
3. Create Storage Account: `tfstateazgitea`
   - Performance: Standard
   - Replication: LRS
   - Secure transfer: Enabled
   - Public access: Disabled
4. Create Container: `tfstate`
   - Private access level

## Pipeline Changes Required

No changes needed! The backend configuration is already in `provider.tf`:

```terraform
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "tfstateazgitea"
  container_name       = "tfstate"
  key                  = "gitea-azure-infra.tfstate"
}
```

## After Setup

1. First pipeline run will initialize the backend
2. State will be stored in Azure Storage (survives workspace cleanup)
3. Subsequent runs will use the persisted state
4. No more "resource already exists" errors

## Troubleshooting

### "Failed to get existing workspaces"
- Verify storage account exists: `az storage account show -n tfstateazgitea`
- Check container exists: `az storage container show -n tfstate --account-name tfstateazgitea`

### "Error loading state: AccessDenied"
- Verify Jenkins service principal has access to storage account
- Add `Storage Blob Data Contributor` role to service principal

### Reset State (Danger!)
```bash
# Only if you need to start completely fresh
az storage blob delete \
  --container-name tfstate \
  --name gitea-azure-infra.tfstate \
  --account-name tfstateazgitea
```

## Important Notes

⚠️ **DO NOT DELETE** `rg-terraform-state` resource group
⚠️ State file contains **sensitive data** - storage account has encryption enabled
✅ State locking is automatic with Azure Storage backend
