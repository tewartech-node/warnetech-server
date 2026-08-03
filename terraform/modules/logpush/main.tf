/**
 * Phase 6: Logging & Audit Trail
 * Configures Logpush for audit logging
 */

resource "cloudflare_logpush_job" "http_logs" {
  enabled       = var.enable_http_logs
  account_id    = var.account_id
  dataset       = var.http_request_dataset
  frequency     = var.frequency
  destination_conf = var.destination_conf
  ownership_challenge = try(var.ownership_challenge, "")

  depends_on = [
    # Ensure Logpush is set up before creating jobs
  ]
}

resource "cloudflare_logpush_job" "gateway_logs" {
  enabled       = var.enable_gateway_logs
  account_id    = var.account_id
  dataset       = var.gateway_dataset
  frequency     = var.frequency
  destination_conf = var.destination_conf
  ownership_challenge = try(var.ownership_challenge, "")
}

# Optional: Create a separate job for DNS logs
resource "cloudflare_logpush_job" "dns_logs" {
  count         = var.enable_dns_logs ? 1 : 0
  enabled       = true
  account_id    = var.account_id
  dataset       = "gateway_dns"
  frequency     = var.frequency
  destination_conf = var.destination_conf
  ownership_challenge = try(var.ownership_challenge, "")
}
