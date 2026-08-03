# warnetech-server Zero Trust — Terraform IaC

**Deploy complete Zero Trust security in 15 minutes with Terraform.**

Automates all 8 phases of Zero Trust setup instead of manual 2-hour dashboard configuration.

---

## Quick Start (3 commands)

```bash
cd terraform
terraform init                    # Initialize (1 min)
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Cloudflare IDs
terraform apply                   # Deploy (2 min)
```

Done! Your Zero Trust is live.

---

## What Gets Deployed

```
✅ Phase 1: Foundation (account setup)
✅ Phase 2: Authentication + MFA
✅ Phase 3: Access policies for Worker
✅ Phase 4: Firewall rules (WAF, Bot Mgmt, DDoS)
✅ Phase 5: Service tokens for automation
✅ Phase 6: Logging + audit trail
✅ Phase 7: Traffic verification
✅ Phase 8: Monitoring + compliance
```

---

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Main configuration (phases 1-8) |
| `variables.tf` | All input variables |
| `terraform.tfvars.example` | Example configuration (copy & customize) |
| `TERRAFORM_DEPLOYMENT.md` | Step-by-step deployment guide |
| `modules/` | Modular Terraform components |

---

## Requirements

- Terraform >= 1.0
- Cloudflare account with API token
- `terraform.tfvars` with your account/zone IDs

---

## Deployment

See `TERRAFORM_DEPLOYMENT.md` for complete instructions.

**tl;dr:**
```bash
export CLOUDFLARE_API_TOKEN="your-token"
terraform init
terraform plan
terraform apply
```

---

## Architecture

```
terraform/
├── main.tf                    # Entry point (phases 1-8)
├── variables.tf               # Input variables
├── terraform.tfvars.example   # Copy → terraform.tfvars
├── outputs.tf                 # Deployment outputs
│
├── modules/
│   ├── access-application/    # Phase 3: Access app
│   ├── access-policy/         # Phase 3: Access policies
│   ├── firewall-rules/        # Phase 4: WAF rules
│   ├── gateway-rules/         # Phase 4: Gateway
│   └── logpush/               # Phase 6: Logging
│
└── TERRAFORM_DEPLOYMENT.md    # Deployment guide
```

---

## Key Outputs

After `terraform apply`, you get:

```
access_application_id = "..."
firewall_rules = {...}
deployment_status = {...}
```

Save these:
```bash
terraform output -json > deployment-outputs.json
```

---

## Common Tasks

```bash
# View what will be created
terraform plan

# Deploy everything
terraform apply

# Destroy everything (CAREFUL!)
terraform destroy

# Update configuration
# 1. Edit terraform.tfvars
# 2. terraform plan
# 3. terraform apply
```

---

## Comparison: Manual vs Terraform

| Task | Manual | Terraform |
|------|--------|-----------|
| Create Access app | 5 min | 1 min |
| Add policies | 10 min | 1 min |
| Deploy firewall | 15 min | 1 min |
| Setup logging | 10 min | 1 min |
| **Total** | **~2 hours** | **~15 min** |

**Time saved: 1 hour 45 minutes** ⏱️

---

## State Management

Terraform keeps state in `terraform.tfstate` (local by default).

### For production, use remote state:
```hcl
# Uncomment in main.tf
backend "s3" {
  bucket = "warnetech-terraform-state"
  ...
}
```

### Don't commit state files!
```bash
echo "terraform.tfstate*" >> .gitignore
```

---

## Next Steps

1. **Read:** `TERRAFORM_DEPLOYMENT.md` (complete guide)
2. **Setup:** Get Cloudflare credentials
3. **Configure:** Copy & edit `terraform.tfvars`
4. **Deploy:** `terraform init` → `terraform apply`
5. **Verify:** Run `../connectors/verify-traffic.sh`

---

## Support

- **Full guide:** `TERRAFORM_DEPLOYMENT.md`
- **Manual setup:** `../connectors/ZERO_TRUST_SETUP.md`
- **Troubleshooting:** `../RUNBOOK.md`

---

**Status:** ✅ Production-ready  
**Deployment time:** 15 minutes  
**Time saved:** ~2 hours vs manual setup
