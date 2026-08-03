/**
 * Phase 4: Firewall Rules
 * Deploys WAF/DDoS rules for the Worker endpoint
 */

# Challenge rule for low-trust bots
resource "cloudflare_firewall_rule" "challenge_low_trust_bots" {
  zone_id = var.zone_id
  name    = "Challenge low-trust bots"
  action  = "challenge"

  filter_id = cloudflare_firewall_filter.low_trust_bots.id
}

resource "cloudflare_firewall_filter" "low_trust_bots" {
  zone_id = var.zone_id
  name    = "Low trust bot score"

  expression = "(cf.bot_management.score < 30)"
  description = "Challenge requests from bots with low trust score"
}

# Block high-threat traffic
resource "cloudflare_firewall_rule" "block_high_threat" {
  zone_id = var.zone_id
  name    = "Block high threat traffic"
  action  = "block"

  filter_id = cloudflare_firewall_filter.high_threat.id
}

resource "cloudflare_firewall_filter" "high_threat" {
  zone_id = var.zone_id
  name    = "High threat score"

  expression  = "(cf.threat_score > ${var.threat_score_threshold})"
  description = "Block requests with high threat score"
}

# Allow legitimate search engine bots
resource "cloudflare_firewall_rule" "allow_search_bots" {
  zone_id = var.zone_id
  name    = "Allow search engine bots"
  action  = "allow"

  filter_id = cloudflare_firewall_filter.search_bots.id
}

resource "cloudflare_firewall_filter" "search_bots" {
  zone_id = var.zone_id
  name    = "Search engine crawlers"

  expression  = "(cf.verified_bot_category eq \"search engine crawler\")"
  description = "Allow verified search engine crawlers"
}

# Block known malicious IPs
resource "cloudflare_firewall_rule" "block_malicious_ips" {
  zone_id = var.zone_id
  name    = "Block malicious IPs"
  action  = "block"

  filter_id = cloudflare_firewall_filter.malicious_ips.id
}

resource "cloudflare_firewall_filter" "malicious_ips" {
  zone_id = var.zone_id
  name    = "Malicious IPs"

  expression  = "(cf.threat_score > 90 or cf.threat_score >= 50 and cf.bot_management.score < 5)"
  description = "Block IPs identified as malicious"
}

# Log suspicious activity
resource "cloudflare_firewall_rule" "log_suspicious" {
  zone_id = var.zone_id
  name    = "Log suspicious activity"
  action  = "log"

  filter_id = cloudflare_firewall_filter.suspicious_activity.id
}

resource "cloudflare_firewall_filter" "suspicious_activity" {
  zone_id = var.zone_id
  name    = "Suspicious activity"

  expression  = "(cf.bot_management.score < 50 or cf.threat_score > 50)"
  description = "Log all suspicious activity for review"
}

# Default allow rule
resource "cloudflare_firewall_rule" "allow_all" {
  zone_id = var.zone_id
  name    = "Allow all traffic"
  action  = "allow"

  filter_id = cloudflare_firewall_filter.allow_all.id
}

resource "cloudflare_firewall_filter" "allow_all" {
  zone_id = var.zone_id
  name    = "Allow all"

  expression  = "(true)"
  description = "Default allow rule"
}

# Enable WAF managed ruleset
resource "cloudflare_waf_rule" "owasp_rules" {
  count   = var.enable_waf ? 1 : 0
  zone_id = var.zone_id
  group   = "100000"
  mode    = "challenge"
}

# Rate limiting rule
resource "cloudflare_rate_limit" "api_limit" {
  zone_id = var.zone_id
  name    = "Rate limit API endpoints"

  disabled    = !var.enable_rate_limiting
  threshold   = var.rate_limit_threshold
  period      = 60
  match_type  = "request"
  action_id   = "387fa7b180193a7894cee31c89cc8c67"
  action_mode = "challenge"

  match {
    request {
      url_path {
        matches = ["/api/*"]
      }
    }
  }

  description = "Rate limit API requests"
}

# Enable Bot Management
resource "cloudflare_bot_management" "worker_bot_mgmt" {
  count   = var.enable_bot_mgmt ? 1 : 0
  zone_id = var.zone_id
  enabled = true
}

# DDoS protection
resource "cloudflare_ddos_protection_managed" "worker" {
  count   = var.enable_ddos ? 1 : 0
  zone_id = var.zone_id
  enabled = true
}
