output "enabled" {
  description = "Logging enabled status"
  value       = var.enable_http_logs || var.enable_gateway_logs || var.enable_dns_logs
}

output "http_logs_job_id" {
  description = "HTTP logs job ID"
  value       = try(cloudflare_logpush_job.http_logs.id, null)
}

output "gateway_logs_job_id" {
  description = "Gateway logs job ID"
  value       = try(cloudflare_logpush_job.gateway_logs.id, null)
}

output "dns_logs_job_id" {
  description = "DNS logs job ID"
  value       = try(cloudflare_logpush_job.dns_logs[0].id, null)
}

output "logging_summary" {
  description = "Logging configuration summary"
  value = {
    http_logs_enabled    = var.enable_http_logs
    gateway_logs_enabled = var.enable_gateway_logs
    dns_logs_enabled     = var.enable_dns_logs
    destination_type     = var.destination_type
    frequency            = var.frequency
  }
}
