# terraform/environments/test.tfvars
service_name = "hello-world-app"
environment  = "test"
region      = "us-central1"

# Container configuration
container_port = 8080
cpu_limit     = "1000m"
memory_limit  = "512Mi"

# Scaling configuration
min_instances = 1
max_instances = 5

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
      title       = "Test environment access"
      description = "Access to test storage buckets only"
      expression  = "resource.name.startsWith('projects/_/buckets/test-')"
    }
  }
  bigquery_reader = {
    role      = "roles/bigquery.dataViewer"
    condition = null
  }
}

# Environment variables
environment_variables = {
  ENVIRONMENT = "test"
  LOG_LEVEL   = "INFO"
  APP_NAME    = "hello-world-app"
}

# Access configuration
allow_public_access = true
custom_domain      = null

# Health check
health_check_path = "/health"
