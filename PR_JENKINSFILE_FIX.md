## Description

Fix POSIX shell compatibility issue in Jenkinsfile that was causing pipeline failures during Azure credential verification stage.

## Problem

The pipeline was failing with error:

```
Bad substitution
```

This occurred because the shell substring syntax `${ARM_SUBSCRIPTION_ID:0:8}` is bash-specific and not supported by `/bin/sh` (POSIX shell) which Jenkins uses by default.

## Solution

Changed from:

```bash
echo "Subscription ID: ${ARM_SUBSCRIPTION_ID:0:8}..."
```

To:

```bash
echo "Subscription ID: $(echo $ARM_SUBSCRIPTION_ID | cut -c1-8)..."
```

This uses standard POSIX-compliant commands (`echo` and `cut`) that work in any shell.

## Type of Change

- [x] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing

- [x] Jenkinsfile syntax is valid
- [x] Uses POSIX-compliant commands
- [x] No functional changes to credential handling
- [ ] Pipeline runs successfully (to be verified in Jenkins)

## Impact

- Fixes pipeline failure in "Verify Azure Credentials" stage
- No changes to functionality, only shell compatibility
- Single line change

---

**Branch**: `DEMO-23-write-terraform-azure-infra-repo` → `main`
**Commit**: a0dbd2a
