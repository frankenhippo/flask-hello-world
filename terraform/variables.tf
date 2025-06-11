# terraform/variables.tf
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, live)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "live"], var.environment)
    error_message = "Environment must be one of: dev, test, live."
  }
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "service_account_roles" {
  description = "List of IAM roles to assign to the service account"
  type        = list(string)
  default     = []
}

variable "custom_iam_bindings" {
  description = "Map of custom IAM bindings with optional conditions"
  type = map(object({
    role = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = {}
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "allow_public_access" {
  description = "Allow public access to the service"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Custom domain for the service"
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/"
}
