#!/bin/bash
# Script to create Azure Storage Account for Terraform remote backend
# This should be run once before first deployment

set -e

echo "=========================================="
echo "Creating Azure Storage Account for Terraform Backend"
echo "=========================================="

# Variables
RESOURCE_GROUP="tfstate-rg"
STORAGE_ACCOUNT="tfstateazuregitea"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Check if already exists
if az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "✅ Resource group $RESOURCE_GROUP already exists"
else
    echo "📦 Creating resource group $RESOURCE_GROUP..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# Check if storage account exists
if az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP &>/dev/null; then
    echo "✅ Storage account $STORAGE_ACCOUNT already exists"
else
    echo "💾 Creating storage account $STORAGE_ACCOUNT..."
    az storage account create \
      --resource-group $RESOURCE_GROUP \
      --name $STORAGE_ACCOUNT \
      --sku Standard_LRS \
      --encryption-services blob \
      --location $LOCATION
fi

# Get storage account key
echo "🔑 Getting storage account key..."
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Check if container exists
if az storage container show --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --account-key "$ACCOUNT_KEY" &>/dev/null; then
    echo "✅ Container $CONTAINER_NAME already exists"
else
    echo "📁 Creating container $CONTAINER_NAME..."
    az storage container create \
      --name $CONTAINER_NAME \
      --account-name $STORAGE_ACCOUNT \
      --account-key "$ACCOUNT_KEY"
fi

echo ""
echo "=========================================="
echo "✅ Backend storage configured successfully!"
echo "=========================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"
echo "=========================================="
