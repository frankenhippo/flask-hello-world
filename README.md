# Cloud Run Flask/Streamlit CI/CD Template

A comprehensive template for deploying Flask and Streamlit applications to Google Cloud Run using Terraform and Cloud Build CI/CD pipelines.

## 🚀 Features

- **Multi-environment deployment** (dev, test, live)
- **Terraform Infrastructure as Code** with environment-specific configurations
- **Cloud Build CI/CD pipeline** with automatic deployments
- **Service account management** with customizable IAM roles and scopes
- **Artifact Registry integration** for container storage
- **Health checks and monitoring** built-in
- **Flexible application support** (Flask or Streamlit)
- **Security best practices** with non-root containers and filtered environment variables

## 📁 Project Structure

```
├── app/
│   ├── app.py              # Flask application
│   ├── streamlit_app.py    # Streamlit application
│   ├── Dockerfile          # Container configuration
│   └── requirements.txt    # Python dependencies
├── terraform/
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   └── environments/
│       ├── dev.tfvars     # Development environment config
│       ├── test.tfvars    # Test environment config
│       └── live.tfvars    # Production environment config
├── cloudbuild.yaml        # Cloud Build pipeline configuration
├── cloud-build-triggers.yaml  # Build trigger configurations
└── README.md             # This file
```

## 🛠️ Prerequisites

1. **Google Cloud Project** with billing enabled
2. **APIs enabled**:
   - Cloud Run API
   - Cloud Build API
   - Artifact Registry API
   - IAM API

3. **Terraform State Bucket**: Create a GCS bucket for Terraform state
   ```bash
   gsutil mb gs://your-terraform-state-bucket
   ```

4. **Cloud Build Service Account Permissions**:
   ```bash
   gcloud projects add-iam-policy-binding PROJECT_ID \
       --member="serviceAccount:PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
       --role="roles/run.admin"
   
   gcloud projects add-iam-policy-binding PROJECT_ID \
       --member="serviceAccount:PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
       --role="roles/iam.serviceAccountUser"
   ```

## 🚀 Quick Start

### 1. Clone and Customize

```bash
git clone <this-repo>
cd cloud-run-cicd-template
```

### 2. Update Configuration

**Update `cloudbuild.yaml`:**
```yaml
substitutions:
  _SERVICE_NAME: 'your-app-name'           # Change this
  _TF_STATE_BUCKET: 'your-tf-state-bucket' # Change this
```

**Update environment tfvars files** in `terraform/environments/`:
- `dev.tfvars`
- `test.tfvars` 
- `live.tfvars`

### 3. Choose Your Application Type

**For Flask (default):**
- The Dockerfile is already configured for Flask
- Customize `app/app.py` with your application logic

**For Streamlit:**
- Uncomment the Streamlit CMD in `app/Dockerfile`
- Comment out the Flask CMD
- Customize `app/streamlit_app.py` with your application

### 4. Set Up Cloud Build Triggers

```bash
# Apply the trigger configurations
gcloud alpha builds triggers import --source=cloud-build-triggers.yaml

# Or create triggers manually in Cloud Console
```

### 5. Deploy

**Manual deployment:**
```bash
gcloud builds submit --config=cloudbuild.yaml \
    --substitutions=_ENVIRONMENT=dev,_SERVICE_NAME=your-app-name
```

**Automatic deployment:**
- Push to `main` branch → deploys to dev
- Push to `test` branch → deploys to test  
- Create version tag (e.g., `v1.0.0`) → deploys to live

## ⚙️ Configuration Options

### Service Account IAM Roles

Configure in your `.tfvars` files:

```hcl
# Basic roles for logging and monitoring
service_account_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/cloudtrace.agent"
]

# Custom IAM bindings with conditions
custom_iam_bindings = {
  storage_reader = {
    role = "roles/storage.objectViewer"
    condition = {
      title       = "Environment-specific access"
      description = "Access to environment-specific buckets only"
      expression  = "resource.name.startsWith('projects/_/buckets/dev-')"
    }
  }
  bigquery_reader = {
    role      = "roles/bigquery.dataViewer"
    condition = null  # No condition
  }
}
```

### Environment Variables

```hcl
environment_variables = {
  ENVIRONMENT = "development"
  LOG_LEVEL   = "DEBUG"
  APP_NAME    = "your-app-name"
  # Add your custom variables here
}
```

### Scaling Configuration

```hcl
min_instances = 0    # Scale to zero for cost savings
max_instances = 10   # Maximum concurrent instances
cpu_limit     = "1000m"  # 1 vCPU
memory_limit  = "512Mi"  # 512MB RAM
```

## 🔧 Customization Guide

### Adding New Environments

1. Create new tfvars file: `terraform/environments/staging.tfvars`
2. Add new trigger in `cloud-build-triggers.yaml`
3. Update variable validation in `terraform/variables.tf`

### Adding Custom Resources

Add to `terraform/main.tf`:

```hcl
# Example: Cloud SQL instance
resource "google_sql_database_instance" "main" {
  name   = "${var.service_name}-${var.environment}-db"
  region = var.region
  # ... configuration
}
```

### Custom Domains

Set in your tfvars:
```hcl
custom_domain = "api.yourdomain.com"
```

Don't forget to verify domain ownership in Google Cloud Console.

## 🔍 Monitoring and Debugging

### View Logs
```bash
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=your-service-name"
```

### Check Service Status
```bash
gcloud run services describe your-service-name --region=us-central1
```

### Debug Build Issues
```bash
gcloud builds list --limit=10
gcloud builds log BUILD_ID
```

## 🛡️ Security Best Practices

- ✅ Non-root container user
- ✅ Minimal base image (python:3.11-slim)
- ✅ Environment variable filtering (no secrets in logs)
- ✅ IAM conditions for fine-grained access control
- ✅ Health checks for reliability
- ✅ Separate service accounts per environment

## 📊 Cost Optimization

- **Scale to zero**: Set `min_instances = 0` for dev/test
- **Right-sizing**: Adjust CPU/memory limits based on actual usage
- **Regional deployment**: Use closest region to users
- **Artifact Registry**: Automatic image cleanup policies

## 🔄 Migration Guide

### From Existing Flask App

1. Copy your Flask code to `app/app.py`
2. Update `app/requirements.txt` with your dependencies
3. Ensure your app listens on port 8080
4. Add `/health` endpoint for health checks

### From Existing Streamlit App

1. Copy your Streamlit code to `app/streamlit_app.py`
2. Update Dockerfile to use Streamlit CMD
3. Update `app/requirements.txt`
4. Test locally: `streamlit run app/streamlit_app.py --server.port=8080`

## 🆘 Troubleshooting

### Build Failures

**Permission Denied:**
- Check Cloud Build service account has required roles
- Verify Terraform state bucket permissions

**Image Push Failed:**
- Ensure Artifact Registry API is enabled
- Check repository exists and has correct permissions

### Deployment Issues

**Service Won't Start:**
- Check application logs: `gcloud logs read`
- Verify health check endpoint returns 200
- Check environment variables are set correctly

**Traffic Not Routing:**
- Verify `allow_public_access = true` in tfvars
- Check custom domain DNS configuration
- Confirm IAM policy for public access

### Terraform Errors

**State Lock:**
```bash
terraform force-unlock LOCK_ID
```

**Resource Already Exists:**
```bash
terraform import google_cloud_run_v2_service.service projects/PROJECT_ID/locations/REGION/services/SERVICE_NAME
```

## 📚 Additional Resources

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Streamlit Documentation](https://docs.streamlit.io/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This template is provided under the MIT License. See LICENSE file for details.

---

**Happy Deploying! 🚀**
