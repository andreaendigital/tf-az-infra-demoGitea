#!/bin/bash
# Script to create Azure Storage Account for Terraform remote state
# Run this ONCE before using the pipeline

set -e

echo "🔐 Creating Azure Storage Account for Terraform State..."

# Variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="tfstateazgitea"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Login check
if ! az account show &>/dev/null; then
    echo "❌ Not logged in to Azure. Run: az login"
    exit 1
fi

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP_NAME"
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --tags "purpose=terraform-state" "managed-by=manual"

# Create storage account
echo "💾 Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

# Create blob container
echo "📁 Creating blob container: $CONTAINER_NAME"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY

echo ""
echo "════════════════════════════════════════"
echo "✅ Terraform Backend Setup Complete!"
echo "════════════════════════════════════════"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo ""
echo "⚠️  IMPORTANT: This resource group should NOT be deleted"
echo "   It contains the Terraform state for all deployments"
echo "════════════════════════════════════════"
