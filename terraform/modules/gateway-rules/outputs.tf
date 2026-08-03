output "rule_ids" {
  description = "Gateway rule IDs"
  value       = []
  # Gateway rules API support varies by Terraform provider version
  # Manually deploy via Cloudflare Dashboard or API
}

output "status" {
  description = "Gateway configuration status"
  value = {
    http_policies_enabled = var.enable_http_policies
    dns_policies_enabled  = var.enable_dns_policies
    management_configured = true
  }
}
