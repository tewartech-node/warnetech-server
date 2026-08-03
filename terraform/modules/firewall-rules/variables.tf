variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "worker_domain" {
  description = "Worker domain to protect"
  type        = string
  default     = "testllm.warnetwork.cloud"
}

variable "enable_waf" {
  description = "Enable WAF rules"
  type        = bool
  default     = true
}

variable "enable_bot_mgmt" {
  description = "Enable bot management"
  type        = bool
  default     = true
}

variable "enable_ddos" {
  description = "Enable DDoS protection"
  type        = bool
  default     = true
}

variable "enable_rate_limiting" {
  description = "Enable rate limiting"
  type        = bool
  default     = true
}

variable "threat_score_threshold" {
  description = "Threat score threshold for blocking"
  type        = number
  default     = 70
}

variable "rate_limit_threshold" {
  description = "Rate limit threshold (requests per minute)"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
