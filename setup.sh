#!/bin/bash
# setup.sh - Initial setup script for the Cloud Run CI/CD template

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if gcloud is authenticated
check_gcloud_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud authentication found"
        print_status "Please run: gcloud auth login"
        exit 1
    fi
}

# Function to enable required APIs
enable_apis() {
    local project_id=$1
    local apis=(
        "run.googleapis.com"
        "cloudbuild.googleapis.com"
        "artifactregistry.googleapis.com"
        "iam.googleapis.com"
    )
    
    print_status "Enabling required APIs..."
    
    for api in "${apis[@]}"; do
        print_status "Enabling $api..."
        gcloud services enable "$api" --project="$project_id"
    done
    
    print_success "All APIs enabled successfully"
}

# Function to create Terraform state bucket
create_tf_state_bucket() {
    local project_id=$1
    local bucket_name=$2
    local region=$3
    
    print_status "Creating Terraform state bucket: $bucket_name"
    
    if gsutil ls -b "gs://$bucket_name" >/dev/null 2>&1; then
        print_warning "Bucket $bucket_name already exists"
    else
        gsutil mb -p "$project_id" -c STANDARD -l "$region" "gs://$bucket_name"
        print_success "Created bucket: $bucket_name"
    fi
    
    # Enable versioning for state file protection
    gsutil versioning set on "gs://$bucket_name"
    print_success "Enabled versioning on bucket"
}

# Function to configure Cloud Build service account
configure_cloud_build() {
    local project_id=$1
    
    print_status "Configuring Cloud Build service account permissions..."
    
    # Get project number
    local project_number=$(gcloud projects describe "$project_id" --format="value(projectNumber)")
    local cloud_build_sa="${project_number}@cloudbuild.gserviceaccount.com"
    
    # Required roles for Cloud Build
    local roles=(
        "roles/run.admin"
        "roles/iam.serviceAccountUser"
        "roles/artifactregistry.admin"
        "roles/compute.admin"
    )
    
    for role in "${roles[@]}"; do
        print_status "Adding role $role to Cloud Build service account..."
        gcloud projects add-iam-policy-binding "$project_id" \
            --member="serviceAccount:$cloud_build_sa" \
            --role="$role" \
            --quiet \
            --condition=None
    done
    
    print_success "Cloud Build service account configured"
}

# Function to validate Terraform files
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    cd terraform
    terraform init -backend=false
    terraform validate
    cd ..
    
    print_success "Terraform configuration is valid"
}

# Function to test Docker build
test_docker_build() {
    print_status "Testing Docker build..."
    
    cd app
    docker build -t test-build .
    docker rmi test-build
    cd ..
    
    print_success "Docker build test successful"
}

# Main setup function
main() {
    print_status "Starting Cloud Run CI/CD Template Setup"
    print_status "======================================"
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed"
        print_status "Please install from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed"
        print_status "Please install from: https://www.terraform.io/downloads"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        print_status "Please install from: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    print_success "All prerequisites are installed"
    
    # Check gcloud authentication
    check_gcloud_auth
    print_success "gcloud authentication verified"
    
    # Get project ID
    local project_id
    if [ -n "$1" ]; then
        project_id=$1
    else
        project_id=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$project_id" ]; then
            print_error "No project ID specified and no default project set"
            print_status "Usage: $0 [PROJECT_ID]"
            print_status "Or set default project: gcloud config set project PROJECT_ID"
            exit 1
        fi
    fi
    
    print_status "Using project: $project_id"
    
    # Get region
    local region
    region=$(gcloud config get-value compute/region 2>/dev/null)
    if [ -z "$region" ]; then
        region="us-central1"
        print_warning "No default region set, using: $region"
    fi
    
    print_status "Using region: $region"
    
    # Generate bucket name
    local bucket_name="${project_id}-terraform-state"
    
    # Enable APIs
    enable_apis "$project_id"
    
    # Create Terraform state bucket
    create_tf_state_bucket "$project_id" "$bucket_name" "$region"
    
    # Configure Cloud Build
    configure_cloud_build "$project_id"
    
    # Validate Terraform
    validate_terraform
    
    # Test Docker build (optional)
    if command_exists docker && docker info >/dev/null 2>&1; then
        test_docker_build
    else
        print_warning "Docker daemon not running, skipping build test"
    fi
    
    # Update configuration files
    print_status "Updating configuration files..."
    
    # Update cloudbuild.yaml
    sed -i.bak "s/your-terraform-state-bucket/$bucket_name/g" cloudbuild.yaml
    rm cloudbuild.yaml.bak 2>/dev/null || true
    
    # Update trigger configuration
    sed -i.bak "s/your-terraform-state-bucket/$bucket_name/g" cloud-build-triggers.yaml
    rm cloud-build-triggers.yaml.bak 2>/dev/null || true
    
    print_success "Configuration files updated"
    
    # Final instructions
    print_success "Setup completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Update terraform/environments/*.tfvars with your service name"
    print_status "2. Update cloud-build-triggers.yaml with your GitHub repo details"
    print_status "3. Choose Flask or Streamlit in app/Dockerfile"
    print_status "4. Set up Cloud Build triggers:"
    print_status "   gcloud alpha builds triggers import --source=cloud-build-triggers.yaml"
    print_status "5. Deploy manually or push to trigger automatic deployment"
    print_status ""
    print_status "Manual deployment:"
    print_status "   gcloud builds submit --config=cloudbuild.yaml --substitutions=_ENVIRONMENT=dev"
    print_status ""
    print_status "For more information, see README.md"
}

# Run main function with all arguments
main "$@"
