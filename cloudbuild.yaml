# Terraform configuration for Google Cloud Run deployment with Artifact Registry

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    # Configure via terraform init with -backend-config
    # bucket = "your-terraform-state-bucket"
    # prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create Artifact Registry repository FIRST
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${var.service_name}-${var.environment}"
  description   = "Docker repository for ${var.service_name} ${var.environment} environment"
  format        = "DOCKER"
  
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old-versions"
    action = "DELETE" 
    older_than = "30d"
  }
}

# IAM Service Account for Cloud Run
resource "google_service_account" "cloudrun_service_account" {
  account_id   = "${var.service_name}-${var.environment}-sa"
  display_name = "${var.service_name} ${var.environment} Service Account"
  description  = "Service account for ${var.service_name} Cloud Run service in ${var.environment}"
}

# Apply base IAM roles to service account
resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.service_account_roles)
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudrun_service_account.email}"
}

# Apply custom IAM bindings with conditions
resource "google_project_iam_member" "custom_bindings" {
  for_each = var.custom_iam_bindings
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.cloudrun_service_account.email}"
  
  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "service" {
  name     = "${var.service_name}-${var.environment}"
  location = var.region
  
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"
  
  template {
    service_account = google_service_account.cloudrun_service_account.email
    
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    containers {
      # Use the Artifact Registry repository we created
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/${var.service_name}:latest"
      
      ports {
        container_port = 8080
      }
      
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle = true
      }
      
      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
      
      # Health check probe
      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
      
      liveness_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }
  }
  
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
  
  depends_on = [google_artifact_registry_repository.main]
}

# IAM policy for public access (if enabled)
resource "google_cloud_run_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0
  
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Custom domain mapping (if specified)
resource "google_cloud_run_domain_mapping" "domain" {
  count = var.custom_domain != null ? 1 : 0
  
  location = var.region
  name     = var.custom_domain
  
  metadata {
    namespace = var.project_id
  }
  
  spec {
    route_name = google_cloud_run_v2_service.service.name
  }
}
