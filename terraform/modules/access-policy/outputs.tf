output "policy_id" {
  description = "Access policy ID (first policy created)"
  value       = cloudflare_access_policy.authenticated_users.id
}

output "policies" {
  description = "All created policies"
  value = {
    authenticated_users = cloudflare_access_policy.authenticated_users.id
    service_tokens      = cloudflare_access_policy.service_tokens.id
    deny_all            = cloudflare_access_policy.deny_all.id
  }
}

output "service_token_id" {
  description = "Service token ID"
  value       = cloudflare_access_service_token.connector_token.id
  sensitive   = true
}

output "service_token_name" {
  description = "Service token name"
  value       = cloudflare_access_service_token.connector_token.name
}
