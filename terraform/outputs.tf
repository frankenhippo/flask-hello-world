# terraform/outputs.tf
output "service_url" {
  description = "URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.service.uri
}

output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.service_account.email
}

output "repository_url" {
  description = "URL of the Artifact Registry repository"
  value       = google_artifact_registry_repository.repo.name
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.name
}

output "image_url" {
  description = "Full URL of the deployed container image"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}/${var.service_name}:${var.image_tag}"
}
