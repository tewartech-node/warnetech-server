/**
 * Phase 3: Identity & Access Management
 * Creates Cloudflare Access application for the Worker endpoint
 */

resource "cloudflare_access_application" "worker" {
  account_id       = var.account_id
  name             = var.app_name
  domain           = var.app_domain
  type             = "self_hosted"
  session_duration = "${var.session_duration}m"

  allowed_idps = [
    cloudflare_access_identity_provider.cloudflare.id
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to prevent unnecessary updates
      cors_headers
    ]
  }
}

# Configure Cloudflare as identity provider
resource "cloudflare_access_identity_provider" "cloudflare" {
  account_id = var.account_id
  name       = "Cloudflare"
  type       = "cloudflare"

  config {
    client_id     = ""  # Cloudflare built-in
    client_secret = ""  # Cloudflare built-in
  }
}

# OAuth providers (optional but recommended)
resource "cloudflare_access_identity_provider" "google" {
  account_id = var.account_id
  name       = "Google"
  type       = "google"

  config {
    client_id     = var.google_oauth_client_id
    client_secret = var.google_oauth_client_secret
  }
}

# GitHub OAuth (for development/testing)
resource "cloudflare_access_identity_provider" "github" {
  account_id = var.account_id
  name       = "GitHub"
  type       = "github"

  config {
    client_id     = var.github_oauth_client_id
    client_secret = var.github_oauth_client_secret
  }
}

# Session policy
resource "cloudflare_access_application_cors_headers" "worker_cors" {
  account_id = var.account_id
  app_id     = cloudflare_access_application.worker.id

  allowed_origins = [
    var.app_domain,
    "https://testllm.warnetwork.cloud"
  ]

  allowed_methods = [
    "GET",
    "POST",
    "OPTIONS",
    "HEAD"
  ]

  allow_credentials = true
}

# Application settings
resource "cloudflare_access_application_settings" "worker" {
  account_id = var.account_id
  app_id     = cloudflare_access_application.worker.id

  session_duration = "${var.session_duration}m"

  # Require re-auth for sensitive operations
  custom_denied_message = "Access denied. Please contact your administrator."
  enable_binding_cookie = true
}
