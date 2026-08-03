output "application_id" {
  description = "Access application ID"
  value       = cloudflare_access_application.worker.id
}

output "application_name" {
  description = "Access application name"
  value       = cloudflare_access_application.worker.name
}

output "application_domain" {
  description = "Access application domain"
  value       = cloudflare_access_application.worker.domain
}

output "cloudflare_idp_id" {
  description = "Cloudflare identity provider ID"
  value       = cloudflare_access_identity_provider.cloudflare.id
}

output "google_idp_id" {
  description = "Google identity provider ID"
  value       = try(cloudflare_access_identity_provider.google.id, null)
}

output "github_idp_id" {
  description = "GitHub identity provider ID"
  value       = try(cloudflare_access_identity_provider.github.id, null)
}
