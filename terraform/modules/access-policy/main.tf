/**
 * Phase 3: Access Policies
 * Defines who can access the Worker and under what conditions
 */

# Allow authenticated users policy
resource "cloudflare_access_policy" "authenticated_users" {
  account_id     = var.account_id
  application_id = var.application_id
  name           = "Allow authenticated users"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = var.authenticated_domains
  }

  dynamic "require" {
    for_each = var.require_mfa ? [1] : []
    content {
      login_method = ["mfa"]
    }
  }
}

# Allow service tokens (for automation)
resource "cloudflare_access_policy" "service_tokens" {
  account_id     = var.account_id
  application_id = var.application_id
  name           = "Allow service tokens"
  precedence     = 2
  decision       = "allow"

  include {
    service_token = [
      cloudflare_access_service_token.connector_token.id
    ]
  }
}

# Deny everything else (default deny policy)
resource "cloudflare_access_policy" "deny_all" {
  account_id     = var.account_id
  application_id = var.application_id
  name           = "Deny all other access"
  precedence     = 100
  decision       = "deny"

  include {
    everyone = true
  }
}

# Create service token for automation/connectors
resource "cloudflare_access_service_token" "connector_token" {
  account_id = var.account_id
  name       = "warnetech-connector-token"

  min_days_for_renewal = 30
}

# Service token policy
resource "cloudflare_access_policy" "service_token_policy" {
  account_id     = var.account_id
  application_id = var.application_id
  name           = "Service Token Policy"
  precedence     = 3
  decision       = "allow"

  include {
    service_token = [
      cloudflare_access_service_token.connector_token.id
    ]
  }

  require {
    login_method = ["mfa"]
  }
}

# Device posture check (optional, requires WARP)
resource "cloudflare_access_policy" "device_posture" {
  count          = var.require_device_posture ? 1 : 0
  account_id     = var.account_id
  application_id = var.application_id
  name           = "Require device posture"
  precedence     = 5
  decision       = "allow"

  include {
    email_domain = var.authenticated_domains
  }

  require {
    login_method = ["mfa"]
    # Note: Device posture rules need to be created separately
  }
}

# Geo-blocking policy (optional)
resource "cloudflare_access_policy" "geo_blocking" {
  count          = length(var.blocked_countries) > 0 ? 1 : 0
  account_id     = var.account_id
  application_id = var.application_id
  name           = "Block high-risk countries"
  precedence     = 10
  decision       = "deny"

  include {
    geo = var.blocked_countries
  }
}
