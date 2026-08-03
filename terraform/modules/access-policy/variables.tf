variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "application_id" {
  description = "Access application ID"
  type        = string
}

variable "require_authenticated" {
  description = "Require authentication for access"
  type        = bool
  default     = true
}

variable "authenticated_domains" {
  description = "Email domains allowed to access"
  type        = list(string)
  default     = ["warnetwork.cloud"]
}

variable "require_mfa" {
  description = "Require MFA for all access"
  type        = bool
  default     = true
}

variable "require_device_posture" {
  description = "Require device posture checks (requires WARP)"
  type        = bool
  default     = false
}

variable "blocked_countries" {
  description = "Countries to block access from"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
