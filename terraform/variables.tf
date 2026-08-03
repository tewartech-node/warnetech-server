variable "cloudflare_api_token" {
  description = "Cloudflare API token (set via environment: CLOUDFLARE_API_TOKEN)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for warnetwork.cloud"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}

# ============================================================================
# Worker Configuration
# ============================================================================

variable "worker_domain" {
  description = "Worker domain (e.g., testllm.warnetwork.cloud)"
  type        = string
  default     = "testllm.warnetwork.cloud"
}

# ============================================================================
# Phase 2: Authentication & Device Posture
# ============================================================================

variable "authenticated_email_domains" {
  description = "Email domains that can authenticate"
  type        = list(string)
  default     = ["warnetwork.cloud"]
}

variable "require_mfa" {
  description = "Require MFA for all access"
  type        = bool
  default     = true
}

variable "session_duration_minutes" {
  description = "Session timeout in minutes"
  type        = number
  default     = 480 # 8 hours
}

# ============================================================================
# Phase 4: Firewall & Gateway Rules
# ============================================================================

variable "bot_management_threshold" {
  description = "Bot management score threshold (0-100, lower = more suspicious)"
  type        = number
  default     = 30

  validation {
    condition     = var.bot_management_threshold >= 0 && var.bot_management_threshold <= 100
    error_message = "Bot management threshold must be between 0 and 100."
  }
}

variable "threat_score_block_threshold" {
  description = "Threat score threshold for blocking (0-100, higher = more threats)"
  type        = number
  default     = 70

  validation {
    condition     = var.threat_score_block_threshold >= 0 && var.threat_score_block_threshold <= 100
    error_message = "Threat score threshold must be between 0 and 100."
  }
}

variable "enable_rate_limiting" {
  description = "Enable rate limiting on worker endpoint"
  type        = bool
  default     = true
}

variable "rate_limit_requests_per_minute" {
  description = "Rate limit: requests per minute"
  type        = number
  default     = 100
}

variable "rate_limit_burst_size" {
  description = "Rate limit: burst size"
  type        = number
  default     = 10
}

# ============================================================================
# Phase 6: Logging & Audit Trail
# ============================================================================

variable "logpush_destination_type" {
  description = "Logpush destination type (cloudflare_logpush, s3, gcs, datadog)"
  type        = string
  default     = "cloudflare_logpush"

  validation {
    condition     = contains(["cloudflare_logpush", "s3", "gcs", "datadog", "splunk"], var.logpush_destination_type)
    error_message = "Logpush destination must be cloudflare_logpush, s3, gcs, datadog, or splunk."
  }
}

variable "logpush_destination_config" {
  description = "Logpush destination configuration (varies by type)"
  type        = map(string)
  default = {
    bucket = "warnetech-logs"
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 90
}

# ============================================================================
# Zero Trust Gateway Configuration
# ============================================================================

variable "gateway_proxy_enabled" {
  description = "Enable Cloudflare Gateway proxy"
  type        = bool
  default     = true
}

variable "split_tunnel_mode" {
  description = "Split tunnel mode (include or exclude)"
  type        = string
  default     = "exclude"

  validation {
    condition     = contains(["include", "exclude"], var.split_tunnel_mode)
    error_message = "Split tunnel mode must be include or exclude."
  }
}

variable "split_tunnel_includes" {
  description = "CIDRs to include in split tunnel"
  type        = list(string)
  default = [
    "10.64.0.0/12",
    "100.64.0.0/10",
    "100.80.0.0/16"
  ]
}

variable "split_tunnel_excludes" {
  description = "CIDRs to exclude from split tunnel"
  type        = list(string)
  default = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}

variable "split_dns_domains" {
  description = "Domains for split DNS"
  type = map(object({
    upstream = string
  }))
  default = {
    "*.warnetech.cloud" = {
      upstream = "1.1.1.1"
    }
    "*.warnetwork.cloud" = {
      upstream = "1.1.1.1"
    }
  }
}

# ============================================================================
# VPC Connector Configuration
# ============================================================================

variable "vpc_connector_name" {
  description = "VPC connector name"
  type        = string
  default     = "warnetech-server-vpc"
}

variable "vpc_connector_node_id" {
  description = "VPC connector node ID"
  type        = string
  default     = "457874e2-ac23-45d5-b2ab-4e36360e21a5"
}

# ============================================================================
# Backup Configuration
# ============================================================================

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_account_email" {
  description = "Backup Google Drive account email"
  type        = string
  default     = "warnet.dev01@gmail.com"
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}

# ============================================================================
# Tagging & Organization
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "warnetech-server"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
