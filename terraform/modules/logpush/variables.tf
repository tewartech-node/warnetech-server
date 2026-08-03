variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "enable_http_logs" {
  description = "Enable HTTP request logging"
  type        = bool
  default     = true
}

variable "enable_gateway_logs" {
  description = "Enable gateway HTTP logging"
  type        = bool
  default     = true
}

variable "enable_dns_logs" {
  description = "Enable DNS logging"
  type        = bool
  default     = true
}

variable "http_request_dataset" {
  description = "HTTP request dataset name"
  type        = string
  default     = "http_requests"
}

variable "gateway_dataset" {
  description = "Gateway dataset name"
  type        = string
  default     = "gateway_http"
}

variable "frequency" {
  description = "Log push frequency (low, high)"
  type        = string
  default     = "high"
}

variable "destination_type" {
  description = "Logpush destination type"
  type        = string
  default     = "cloudflare_logpush"
}

variable "destination_conf" {
  description = "Destination configuration"
  type        = string
  default     = ""
}

variable "ownership_challenge" {
  description = "Ownership challenge token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
