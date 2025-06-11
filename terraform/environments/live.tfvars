# terraform/environments/live.tfvars
service_name = "hello-world-app"
environment  = "live"
region      = "us-central1"

# Container configuration
container_port = 8080
cpu_limit     = "2000m"
memory_limit  = "1Gi"

# Scaling configuration
min_instances = 2
max_instances = 20

# Service account IAM roles
service_account_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/cloudtrace.agent"
]

# Custom IAM bindings
custom_iam_bindings = {
  storage_reader = {
    role = "roles/storage.objectViewer"
    condition = {
      title       = "Production environment access"
      description = "Access to production storage buckets only"
      expression  = "resource.name.startsWith('projects/_/buckets/prod-')"
    }
  }
  bigquery_reader = {
    role      = "roles/bigquery.dataViewer"
    condition = null
  }
  secret_accessor = {
    role      = "roles/secretmanager.secretAccessor"
    condition = null
  }
}

# Environment variables
environment_variables = {
  ENVIRONMENT = "production"
  LOG_LEVEL   = "WARNING"
  APP_NAME    = "hello-world-app"
}

# Access configuration
allow_public_access = true
custom_domain      = "app.yourdomain.com"  # Update with your domain

# Health check
health_check_path = "/health"
