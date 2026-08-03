variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "enable_http_policies" {
  description = "Enable HTTP gateway policies"
  type        = bool
  default     = true
}

variable "enable_dns_policies" {
  description = "Enable DNS gateway policies"
  type        = bool
  default     = true
}

variable "bot_management_score" {
  description = "Bot management score threshold"
  type        = number
  default     = 30
}

variable "threat_score_block" {
  description = "Threat score threshold for blocking"
  type        = number
  default     = 70
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
