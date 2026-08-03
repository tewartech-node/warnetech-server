/**
 * Phase 4: Gateway Rules (L7 Firewall)
 * Manages Cloudflare Gateway HTTP/DNS policies
 */

resource "cloudflare_zero_trust_gateway_managed_headers" "headers" {
  account_id = var.account_id
}

# Note: Gateway policies require use of the Cloudflare API directly
# as Terraform provider has limited support for all gateway features.
# This is a placeholder for documentation purposes.
#
# To deploy gateway rules, use:
# - Cloudflare Dashboard → Gateway → Firewall Policies
# - Or Cloudflare API directly
# - Or reference: connectors/zero-trust-policy.json for policy definitions
