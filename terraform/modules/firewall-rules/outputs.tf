output "rule_ids" {
  description = "IDs of all firewall rules created"
  value = [
    cloudflare_firewall_rule.challenge_low_trust_bots.id,
    cloudflare_firewall_rule.block_high_threat.id,
    cloudflare_firewall_rule.allow_search_bots.id,
    cloudflare_firewall_rule.block_malicious_ips.id,
    cloudflare_firewall_rule.log_suspicious.id,
    cloudflare_firewall_rule.allow_all.id
  ]
}

output "firewall_rules" {
  description = "Firewall rules summary"
  value = {
    challenge_bots  = cloudflare_firewall_rule.challenge_low_trust_bots.name
    block_threats   = cloudflare_firewall_rule.block_high_threat.name
    allow_bots      = cloudflare_firewall_rule.allow_search_bots.name
    block_malicious = cloudflare_firewall_rule.block_malicious_ips.name
    log_suspicious  = cloudflare_firewall_rule.log_suspicious.name
    allow_all       = cloudflare_firewall_rule.allow_all.name
  }
}

output "waf_enabled" {
  description = "WAF enabled status"
  value       = var.enable_waf
}

output "bot_management_enabled" {
  description = "Bot management enabled status"
  value       = var.enable_bot_mgmt
}

output "rate_limiting_enabled" {
  description = "Rate limiting enabled status"
  value       = var.enable_rate_limiting
}
