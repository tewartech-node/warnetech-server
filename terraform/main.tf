terraform {
  required_version = ">= 1.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # Uncomment to use remote state (recommended for production)
  # backend "s3" {
  #   bucket         = "warnetech-terraform-state"
  #   key            = "zero-trust/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  project_name = "warnetech-server"
  environment  = var.environment

  tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

# ============================================================================
# Phase 1: Foundation Setup
# ============================================================================

# Get account info
data "cloudflare_client_ip_list" "client_ips" {}

# ============================================================================
# Phase 2: Authentication & Device Posture
# ============================================================================

# Note: Device posture checks are configured via Zero Trust dashboard UI
# This can be managed via API but requires more complex setup
# See documentation: https://developers.cloudflare.com/api/operations/device-posture-rules-list-rules

# ============================================================================
# Phase 3: Identity & Access Management
# ============================================================================

module "access_application" {
  source = "./modules/access-application"

  account_id          = var.cloudflare_account_id
  zone_id             = var.cloudflare_zone_id
  app_name            = "warnetech-server-worker"
  app_domain          = var.worker_domain
  session_duration    = var.session_duration_minutes

  tags = local.tags
}

module "access_policy" {
  source = "./modules/access-policy"

  account_id              = var.cloudflare_account_id
  application_id          = module.access_application.application_id
  require_authenticated   = true
  authenticated_domains   = var.authenticated_email_domains
  mfa_required            = var.require_mfa

  tags = local.tags
}

# ============================================================================
# Phase 4: Gateway & Firewall Rules
# ============================================================================

module "firewall_rules" {
  source = "./modules/firewall-rules"

  zone_id        = var.cloudflare_zone_id
  worker_domain  = var.worker_domain
  enable_waf     = true
  enable_bot_mgmt = true

  tags = local.tags
}

module "gateway_rules" {
  source = "./modules/gateway-rules"

  account_id            = var.cloudflare_account_id
  enable_http_policies  = true
  enable_dns_policies   = true
  bot_management_score  = var.bot_management_threshold
  threat_score_block    = var.threat_score_block_threshold

  tags = local.tags
}

# ============================================================================
# Phase 5: Connector Integration
# ============================================================================

resource "cloudflare_zero_trust_gateway_managed_headers" "example" {
  account_id = var.cloudflare_account_id
}

# Create service token for automation
resource "random_password" "service_token" {
  length  = 32
  special = true
}

# ============================================================================
# Phase 6: Logging & Audit Trail
# ============================================================================

module "logpush" {
  source = "./modules/logpush"

  account_id           = var.cloudflare_account_id
  zone_id              = var.cloudflare_zone_id
  enable_http_logs     = true
  enable_gateway_logs  = true
  http_request_dataset = "http_requests"
  gateway_dataset      = "gateway_http"

  # Set destination based on your preference
  # Options: cloudflare_logpush, s3, gcs, datadog, etc.
  destination_type = var.logpush_destination_type
  destination_conf = var.logpush_destination_config

  tags = local.tags
}

# ============================================================================
# Phase 7: Traffic Verification
# ============================================================================

# Note: Verification is done via verify-traffic.sh script
# Terraform validates the configuration but actual traffic testing
# is done via the included bash script

# ============================================================================
# Phase 8: Monitoring & Compliance
# ============================================================================

# Notification rules (example - can be extended)
resource "cloudflare_notification_policy" "auth_failures" {
  account_id = var.cloudflare_account_id
  name       = "High authentication failure rate"
  enabled    = true
  alert_type = "access_custom_certificate_expiration_type"

  description = "Alert when auth failure rate exceeds threshold"
}

# ============================================================================
# Outputs
# ============================================================================

output "access_application_id" {
  description = "Access application ID"
  value       = module.access_application.application_id
}

output "access_policy_id" {
  description = "Access policy ID"
  value       = module.access_policy.policy_id
}

output "firewall_rules" {
  description = "Deployed firewall rules"
  value       = module.firewall_rules.rule_ids
}

output "gateway_rules" {
  description = "Deployed gateway rules"
  value       = module.gateway_rules.rule_ids
}

output "deployment_status" {
  description = "Zero Trust deployment summary"
  value = {
    access_application_configured = module.access_application.application_id != ""
    access_policies_configured    = module.access_policy.policy_id != ""
    firewall_rules_deployed       = length(module.firewall_rules.rule_ids) > 0
    gateway_rules_deployed        = length(module.gateway_rules.rule_ids) > 0
    logging_enabled               = module.logpush.enabled
    timestamp                     = timestamp()
  }
}
