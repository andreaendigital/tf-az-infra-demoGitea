## Description

Use local backend temporarily until Azure CLI is configured on Jenkins server.

## Problem

Azure CLI is not available on Jenkins server, preventing automatic backend setup. Pipeline was failing with:

```
az: not found
```

## Solution

- **`remote_backend_azurerm.tf`**: Commented out remote backend configuration
- **`Jenkinsfile`**: Removed backend setup stage
- Using local backend for now (state stored on Jenkins server)

## Next Steps

1. Install Azure CLI on Jenkins server
2. Create Storage Account manually or via script
3. Uncomment remote backend configuration
4. Migrate state: `terraform init -migrate-state`

## Type of Change

- [x] Bug fix (pipeline no longer fails)
- [ ] New feature
- [ ] Breaking change

## Impact

- ✅ Pipeline can proceed with terraform operations
- ⚠️ State stored locally (not shared)
- ⚠️ No state locking (single-user only for now)

---

**Branch**: `DEMO-23-write-terraform-azure-infra-repo` → `main`
**Commit**: d2e884c
