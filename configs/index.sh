#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required files exist
check_requirements() {
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        log_error "terraform.tfvars file not found!"
        log_info "Copy terraform.tfvars.example to terraform.tfvars and update the values"
        exit 1
    fi

    if [ ! -f "$TERRAFORM_DIR/id_rsa.pub" ]; then
        log_error "SSH public key (id_rsa.pub) not found!"
        log_info "Please generate an SSH key pair:"
        log_info "  ssh-keygen -t rsa -b 4096 -f id_rsa -N ''"
        exit 1
    fi
}

# Extract environment_id from tfvars
get_environment_id() {
    grep -E '^environment_id\s*=' "$TERRAFORM_DIR/terraform.tfvars" | cut -d'"' -f2
}

# Terraform init
init() {
    log_info "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    terraform init
    log_success "Terraform initialized successfully"
}

# Terraform validate
validate() {
    log_info "Validating execution script..."
    cd "$TERRAFORM_DIR"
    terraform validate
}

# Terraform plan
plan() {
    log_info "Creating execution plan..."
    cd "$TERRAFORM_DIR"
    terraform plan -var-file="terraform.tfvars"
}

# Terraform apply
apply() {
    local environment_id=$(get_environment_id)
    
    if [ -z "$environment_id" ]; then
        log_error "Could not extract environment_id from terraform.tfvars"
        exit 1
    fi

    log_warning "This will create infrastructure for environment: $environment_id"
    read -p "Are you sure you want to proceed? (yes/no): " confirmation

    if [ "$confirmation" != "yes" ]; then
        log_info "Apply cancelled"
        exit 0
    fi

    log_info "Applying Terraform configuration..."
    cd "$TERRAFORM_DIR"
    terraform apply -var-file="terraform.tfvars" -auto-approve
    
    log_success "Infrastructure deployed successfully!"
    log_info "Environment: $environment_id"
    
    # Display outputs
    echo
    log_info "Infrastructure Summary:"
    terraform output environment_summary
}

# Terraform destroy
destroy() {
    local environment_id=$(get_environment_id)
    
    if [ -z "$environment_id" ]; then
        log_error "Could not extract environment_id from terraform.tfvars"
        exit 1
    fi

    log_warning "This will DESTROY all infrastructure for environment: $environment_id"
    log_warning "This action cannot be undone!"
    read -p "Type the environment ID '$environment_id' to confirm destruction: " confirmation

    if [ "$confirmation" != "$environment_id" ]; then
        log_info "Destroy cancelled"
        exit 0
    fi

    log_info "Destroying infrastructure..."
    cd "$TERRAFORM_DIR"
    terraform destroy -var-file="terraform.tfvars" -auto-approve
    
    log_success "Infrastructure destroyed successfully!"
}

# Terraform output
show_output() {
    log_info "Displaying Terraform outputs..."
    cd "$TERRAFORM_DIR"
    terraform output
}

# Show usage
usage() {
    echo "Usage: $0 {init|validate|plan|apply|destroy|output|help}"
    echo
    echo "Commands:"
    echo "  init        - Initialize Terraform and providers"
    echo "  validate    - Validate execution script"
    echo "  plan        - Show execution plan"
    echo "  apply       - Create or update infrastructure"
    echo "  destroy     - Destroy all infrastructure"
    echo "  output      - Show Terraform outputs"
    echo "  help        - Show this help message"
    echo
    echo "Requirements:"
    echo "  - terraform.tfvars file (copy from terraform.tfvars.example)"
    echo "  - SSH public key (id_rsa.pub)"
    echo "  - AWS credentials configured"
}

# Main script
case "$1" in
    init)
        check_requirements
        init
        ;;
    validate)
        check_requirements
        validate
        ;;
    plan)
        check_requirements
        plan
        ;;
    apply)
        check_requirements
        apply
        ;;
    destroy)
        check_requirements
        destroy
        ;;
    output)
        check_requirements
        show_output
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        log_error "Invalid command: $1"
        usage
        exit 1
        ;;
esac