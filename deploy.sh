#!/bin/bash

# =====================================================
# Terraform Deployment Script
# Deploys Network, AKS, and PostgreSQL infrastructure
# =====================================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_DIR="${SCRIPT_DIR}/environments/dev"


# =====================================================
# 1. Run subscription Vending
# =====================================================


# =====================================================
# 2. Deploy Network Infrastructure
# =====================================================
print_info "Starting Network Infrastructure Deployment..."
cd "${SCRIPT_DIR}/2-network"

print_info "Initializing Terraform for Network..."
terraform init -reconfigure -backend-config="${ENV_DIR}/backend.tfvars"

print_info "Planning Network deployment..."
terraform plan -var-file="${ENV_DIR}/network.tfvars" -out=network.tfplan

print_info "Applying Network deployment..."
terraform apply network.tfplan

print_info "Network deployment completed successfully!"
echo ""

# =====================================================
# 2. Deploy AKS Cluster
# =====================================================
print_info "Starting AKS Cluster Deployment..."
cd "${SCRIPT_DIR}/3-aks"

print_info "Initializing Terraform for AKS..."
terraform init -reconfigure -backend-config="${ENV_DIR}/backend.tfvars"

print_info "Planning AKS deployment..."
terraform plan -var-file="${ENV_DIR}/aks.tfvars" -out=aks.tfplan

print_info "Applying AKS deployment..."
terraform apply aks.tfplan

print_info "AKS deployment completed successfully!"
echo ""

# =====================================================
# 3. Deploy PostgreSQL
# =====================================================
print_info "Starting PostgreSQL Deployment..."
cd "${SCRIPT_DIR}/4-postgresql"

print_info "Initializing Terraform for PostgreSQL..."
terraform init -reconfigure -backend-config="${ENV_DIR}/postgresql-backend.tfvars"

print_info "Planning PostgreSQL deployment..."
terraform plan -var-file="${ENV_DIR}/postgresql.tfvars" -out=postgresql.tfplan

print_info "Applying PostgreSQL deployment..."
terraform apply postgresql.tfplan

print_info "PostgreSQL deployment completed successfully!"
echo ""

# =====================================================
# Deployment Complete
# =====================================================
print_info "================================================"
print_info "All infrastructure deployed successfully!"
print_info "================================================"
echo ""
print_info "Next steps:"
echo "  1. Configure kubectl: az aks get-credentials --resource-group rg-aks-dev --name aks-dev-australiaeast"
echo "  2. Verify cluster access: kubectl get nodes"
echo "  3. Get PostgreSQL connection details from outputs"
