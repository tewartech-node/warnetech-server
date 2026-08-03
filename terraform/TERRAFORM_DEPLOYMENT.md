# warnetech-server Zero Trust — Terraform Deployment Guide

**Status:** Ready for deployment  
**Time to deploy:** 15 minutes  
**Manual setup time saved:** ~2 hours

---

## Overview

This Terraform configuration automates the complete Zero Trust setup for warnetech-server:
- ✅ Phase 1: Foundation (account setup)
- ✅ Phase 2: Authentication & Device Posture
- ✅ Phase 3: Identity & Access Management (Access policies)
- ✅ Phase 4: Firewall & Gateway Rules
- ✅ Phase 5: Connector Integration (service tokens)
- ✅ Phase 6: Logging & Audit Trail
- ✅ Phase 7: Traffic Verification (via script)
- ✅ Phase 8: Monitoring & Compliance

---

## Prerequisites

### 1. Install Terraform
```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
# Should be >= 1.0
```

### 2. Get Cloudflare Credentials

```bash
# 1. Log into Cloudflare Dashboard
#    https://dash.cloudflare.com

# 2. Get Account ID:
#    Go to any domain → Overview (right sidebar)
#    Copy "Account ID"

# 3. Get Zone ID (for warnetwork.cloud):
#    Go to warnetwork.cloud → Overview
#    Copy "Zone ID"

# 4. Create API Token:
#    My Profile → API Tokens → Create Token
#    Template: "Cloudflare API token" OR create custom with:
#      - Permissions: Account.Access, Zone.Firewall, Zone.Analytics
#      - Resources: Include All Zones
#    → Copy the token
```

**Save these:**
- Account ID: `abc123xyz...`
- Zone ID: `xyz789abc...`
- API Token: `v1.xxx...` (keep secret!)

---

## Deployment Steps

### Step 1: Set Up Terraform Directory

```bash
cd /workspace/warnetech-server/terraform

# Initialize Terraform (downloads provider plugins)
terraform init

# Expected output:
# Terraform has been successfully configured!
# You may now begin working with Terraform. Try running "terraform plan" next.
```

### Step 2: Configure Variables

```bash
# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
# Or: vim terraform.tfvars
# Or: code terraform.tfvars (VS Code)

# Update:
# - cloudflare_account_id = "YOUR-ID"
# - cloudflare_zone_id = "YOUR-ID"
# - authenticated_email_domains = ["warnetwork.cloud"]
```

### Step 3: Set API Token

```bash
# Set as environment variable (recommended for security)
export CLOUDFLARE_API_TOKEN="v1.xxxx..."

# Verify it's set
echo $CLOUDFLARE_API_TOKEN
# Should print your token
```

### Step 4: Review Terraform Plan

```bash
# Generate execution plan
terraform plan

# This shows EXACTLY what will be created
# Review all resources before proceeding
# Expected output:
# Plan: X to add, 0 to change, 0 to destroy.
```

### Step 5: Deploy Zero Trust

```bash
# Apply the configuration
terraform apply

# You'll be asked to confirm:
# Do you want to perform these actions?
# Terraform will perform the actions described above.
# Only 'yes' will be accepted to approve.

# Type: yes
# Press Enter

# Wait for completion (~1-2 minutes)
# Expected output:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

### Step 6: Save Outputs

```bash
# Get important values from output
terraform output

# Expected output:
# access_application_id = "..."
# firewall_rules = {...}
# deployment_status = {...}

# Save these values for reference
terraform output -json > deployment-outputs.json
```

### Step 7: Verify Deployment

```bash
# Test your Access application
curl -v https://testllm.warnetwork.cloud/health

# Expected:
# - 302 (redirect to login) OR
# - 401 (auth required) OR
# - 200 (health check passes)

# Run verification script
cd ../connectors
chmod +x verify-traffic.sh
./verify-traffic.sh

# Expected: 10/10 tests pass (or 8/10 if Warp not active)
```

---

## Terraform State Management

### Local State (Development)
By default, state is stored locally:
```bash
# Files created:
terraform.tfstate          # Your infrastructure state
terraform.tfstate.backup   # Backup of previous state
.terraform/                # Provider plugins cache

# Important: Don't commit to git!
# Add to .gitignore:
echo "terraform.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore
```

### Remote State (Production Recommended)

Uncomment the backend config in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "warnetech-terraform-state"
    key            = "zero-trust/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

Then run:
```bash
terraform init
# Migrate state to S3
# Answer: yes
```

---

## Common Operations

### View Current State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show cloudflare_access_application.worker

# Show all outputs
terraform output
```

### Update Configuration

```bash
# Edit variables
nano terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Destroy Resources (CAREFUL!)

```bash
# Completely remove all infrastructure
terraform destroy

# WARNING: This will delete:
# - Access policies
# - Firewall rules
# - Logging configuration
# - Service tokens
# - Everything created by Terraform

# You'll be prompted to confirm:
# Do you really want to destroy...?
# Type: yes (to confirm)
```

### Emergency Rollback

If something goes wrong:

```bash
# Check what went wrong
terraform plan

# Revert to previous state
terraform state pull > backup.tfstate
git diff terraform.tfstate

# Fix the issue in variables/code, then:
terraform plan
terraform apply
```

---

## Terraform Modules

The configuration uses modular Terraform for clarity:

```
modules/
├── access-application/
│   ├── main.tf         ← Phase 3: Create Access app
│   ├── variables.tf
│   └── outputs.tf
├── access-policy/
│   ├── main.tf         ← Phase 3: Create access policies
│   ├── variables.tf
│   └── outputs.tf
├── firewall-rules/
│   ├── main.tf         ← Phase 4: Deploy firewall
│   ├── variables.tf
│   └── outputs.tf
├── gateway-rules/
│   ├── main.tf         ← Phase 4: Gateway config
│   ├── variables.tf
│   └── outputs.tf
└── logpush/
    ├── main.tf         ← Phase 6: Logging setup
    ├── variables.tf
    └── outputs.tf
```

---

## Troubleshooting

### Error: "API token is invalid"
**Fix:**
```bash
# Verify token is set
echo $CLOUDFLARE_API_TOKEN

# If empty, export it again
export CLOUDFLARE_API_TOKEN="your-token-here"

# Verify it's correct
curl https://api.cloudflare.com/client/v4/accounts \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq .
```

### Error: "Account ID or Zone ID not found"
**Fix:**
```bash
# Double-check values in terraform.tfvars
grep "account_id\|zone_id" terraform.tfvars

# Verify they're correct
curl https://api.cloudflare.com/client/v4/accounts \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq '.result[0].id'
```

### Error: "Resource already exists"
**Fix:**
```bash
# Check if resources already exist manually
# If they do, either:
# 1. Delete them manually from Cloudflare Dashboard
# 2. Import them into Terraform state:
terraform import cloudflare_access_application.worker <app_id>
```

### Plan shows "would destroy" when you don't want to
**Fix:**
```bash
# Make sure you didn't edit terraform.tfstate directly
# Check your variables haven't changed:
terraform plan -out=tfplan

# If the plan looks wrong, abort with:
rm tfplan

# Investigate what changed
git diff terraform.tfvars
```

---

## Advanced: Workspaces

Manage multiple environments with Terraform workspaces:

```bash
# Create workspace for staging
terraform workspace new staging

# Switch workspace
terraform workspace select staging

# Deploy to staging
terraform apply -var-file="staging.tfvars"

# Switch back to production
terraform workspace select default
terraform apply -var-file="terraform.tfvars"

# List workspaces
terraform workspace list
```

---

## Next Steps

1. **Complete deployment (15 min):** Follow Steps 1-7 above
2. **Verify (10 min):** Run `verify-traffic.sh`
3. **Document (5 min):** Save outputs to `deployment-outputs.json`
4. **Backup (2 min):** Commit `terraform.tfvars` + outputs to git (remove secrets!)
5. **Monitor (ongoing):** Check Cloudflare dashboard for activity

---

## Maintenance

### Regular Backups
```bash
# Daily: backup Terraform state
cp terraform.tfstate terraform.tfstate.$(date +%Y%m%d).backup

# Or use remote state (S3, Terraform Cloud, etc.)
```

### Quarterly Review
```bash
# Check for drift (manual changes in Cloudflare Dashboard)
terraform plan

# If drift exists, decide:
# 1. Import changes: terraform import ...
# 2. Or override: terraform apply -refresh-only
```

### Update Terraform
```bash
# Check for updates
terraform version

# Update modules
terraform get -update

# Test in staging first
terraform workspace select staging
terraform plan
```

---

## Support

- **Terraform docs:** https://www.terraform.io/docs
- **Cloudflare provider:** https://registry.terraform.io/providers/cloudflare/cloudflare
- **Zero Trust setup:** See `ZERO_TRUST_SETUP.md` in parent directory
- **Troubleshooting:** See `RUNBOOK.md` in parent directory

---

**Status:** ✅ Ready to deploy  
**Estimated deployment:** 15 minutes  
**Provider:** Cloudflare Terraform provider v4.0+
