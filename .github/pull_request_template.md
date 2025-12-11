## 📋 Pull Request Description
<!-- Provide a clear description of what this PR does -->

## 🔗 Related Issue
<!-- Link to the related issue (e.g., Closes #123, Fixes DEMO-23) -->
Closes #

## 🏗️ Infrastructure Changes
<!-- Check all that apply -->
- [ ] Resource Group modifications
- [ ] Networking changes (VNet, Subnets, NSG)
- [ ] VPN Gateway configuration
- [ ] Database changes (MySQL)
- [ ] Compute changes (VM, scaling)
- [ ] Load Balancer modifications
- [ ] Security updates
- [ ] Monitoring/logging changes
- [ ] Documentation updates
- [ ] CI/CD pipeline changes

## 🔍 Type of Change
<!-- Mark with 'x' -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Infrastructure update (changes to Azure resources)
- [ ] Documentation update
- [ ] Configuration change

## ✅ Testing Checklist
<!-- Verify all applicable items -->
- [ ] Terraform `terraform validate` passes
- [ ] Terraform `terraform plan` reviewed (no unexpected changes)
- [ ] Terraform `terraform fmt` applied
- [ ] Infrastructure deployed to demo environment
- [ ] Manual testing completed
- [ ] All services are functional after deployment
- [ ] No security vulnerabilities introduced
- [ ] Cost impact reviewed and acceptable

## 🧪 Test Evidence
<!-- Provide evidence of testing (screenshots, logs, terraform plan output) -->

### Terraform Plan Output
```hcl
# Paste relevant terraform plan output here
```

### Deployment Verification
```bash
# Commands used to verify deployment
# Output showing successful deployment
```

## 💰 Cost Impact
<!-- Describe any cost implications -->
- **Estimated Monthly Cost Change**: [+/- $X or No Change]
- **Resources Added**: [List new resources]
- **Resources Modified**: [List modified resources]
- **Resources Removed**: [List removed resources]

## 🔒 Security Considerations
<!-- Describe any security implications -->
- [ ] No new security vulnerabilities introduced
- [ ] All secrets handled via Azure Key Vault or Jenkins credentials
- [ ] NSG rules reviewed and appropriate
- [ ] No hardcoded credentials in code
- [ ] Follows least privilege principle

## 📸 Screenshots / Diagrams
<!-- If applicable, add screenshots or architecture diagrams -->

## 🔄 Deployment Plan
<!-- Describe how this should be deployed -->
1. Step 1
2. Step 2
3. ...

## 📝 Rollback Plan
<!-- Describe how to rollback if needed -->
1. Step 1
2. Step 2
3. ...

## 📚 Documentation Updates
<!-- List any documentation that needs to be updated -->
- [ ] README.md updated
- [ ] Architecture diagrams updated
- [ ] Variable documentation updated
- [ ] Deployment guide updated
- [ ] No documentation changes needed

## ⚠️ Breaking Changes
<!-- Describe any breaking changes and migration steps -->
None / Describe breaking changes here

## 👥 Reviewers
<!-- Tag team members who should review -->
@reviewer1 @reviewer2

## 📌 Additional Notes
<!-- Any additional information for reviewers -->
