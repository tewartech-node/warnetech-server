variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "app_name" {
  description = "Access application name"
  type        = string
  default     = "warnetech-server-worker"
}

variable "app_domain" {
  description = "Application domain"
  type        = string
  default     = "testllm.warnetwork.cloud"
}

variable "session_duration" {
  description = "Session duration in minutes"
  type        = number
  default     = 480 # 8 hours
}

variable "google_oauth_client_id" {
  description = "Google OAuth client ID (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_oauth_client_secret" {
  description = "Google OAuth client secret (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_oauth_client_id" {
  description = "GitHub OAuth client ID (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_oauth_client_secret" {
  description = "GitHub OAuth client secret (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
