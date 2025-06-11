# terraform/environments/dev.tfvars
service_name = "hello-world-app"
environment  = "dev"
region      = "us-central1"

# Container configuration
container_port = 8080
cpu_limit     = "500m"
memory_limit  = "256Mi"

# Scaling configuration
min_instances = 0
max_instances = 3

# Service account IAM roles
service_account_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/cloudtrace.agent"
]

# Custom IAM bindings with conditions (example)
custom_iam_bindings = {
  storage_reader = {
    role = "roles/storage.objectViewer"
    condition = {
      title       = "Dev environment access"
      description = "Access to dev storage buckets only"
      expression  = "resource.name.startsWith('projects/_/buckets/dev-')"
    }
  }
}

# Environment variables
environment_variables = {
  ENVIRONMENT = "development"
  LOG_LEVEL   = "DEBUG"
  APP_NAME    = "hello-world-app"
}

# Access configuration
allow_public_access = true
custom_domain      = null

# Health check
health_check_path = "/health"
