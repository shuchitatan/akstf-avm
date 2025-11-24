# =====================================================
# Terraform Deployment Script (PowerShell)
# Deploys Network, AKS, and PostgreSQL infrastructure
# =====================================================

$ErrorActionPreference = "Stop"

# Function to print colored messages
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Step {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor Cyan -NoNewline
    Write-Host "`r  → $Message" -ForegroundColor Cyan
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Get the script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$EnvDir = Join-Path $ScriptDir "environments\dev"

# AKS configuration variables
$ResourceGroup = "rg-aks01-baseline-dev"
$ClusterName = "aks01-baseline-dev"

# =====================================================
# 1. Deploy Network Infrastructure
# =====================================================
# Write-Info "================================================"
# Write-Info "Starting Network Infrastructure Deployment..."
# Write-Info "================================================"
# Set-Location (Join-Path $ScriptDir "2-network")

# Write-Step "Initializing Terraform for Network..."
# terraform init -reconfigure "-backend-config=$EnvDir\backend.tfvars" | Out-Null
# if ($LASTEXITCODE -ne 0) { throw "Network initialization failed" }

# Write-Step "Planning Network deployment..."
# $varFile = Join-Path $EnvDir "network.tfvars"
# terraform plan -var-file $varFile -out network.tfplan
# if ($LASTEXITCODE -ne 0) { throw "Network planning failed" }

# Write-Step "Applying Network deployment..."
# terraform apply network.tfplan
# if ($LASTEXITCODE -ne 0) { throw "Network apply failed" }

# Write-Info "Network deployment completed successfully!"
# Write-Host ""

# =====================================================
# 2. Deploy AKS Cluster
# =====================================================
 Write-Info "================================================"
 Write-Info "Starting AKS Cluster Deployment..."
 Write-Info "================================================"
 Set-Location (Join-Path $ScriptDir "3-aks")

 Write-Step "Initializing Terraform for AKS..."
 terraform init -reconfigure "-backend-config=$EnvDir\aks-backend.tfvars" | Out-Null
 if ($LASTEXITCODE -ne 0) { throw "AKS initialization failed" }

 Write-Step "Planning AKS deployment..."
 $varFile = Join-Path $EnvDir "aks.tfvars"
 terraform plan -var-file $varFile -out aks.tfplan
 if ($LASTEXITCODE -ne 0) { throw "AKS planning failed" }

 Write-Step "Applying AKS deployment..."
 terraform apply aks.tfplan
 if ($LASTEXITCODE -ne 0) { throw "AKS apply failed" }

# az aks get-credentials --resource-group $ResourceGroup --name $ClusterName
# kubectl create namespace development
# kubectl create namespace staging
Write-Step "Disable Cluster auto scaler"
az aks update --resource-group $ResourceGroup --name $ClusterName --disable-cluster-autoscaler
 if ($LASTEXITCODE -ne 0) { throw "AKS disable auto scaler failed" }

 Write-Step "Enabling Istio AKS service mesh..."
 az aks mesh enable --resource-group $ResourceGroup --name $ClusterName
 if ($LASTEXITCODE -ne 0) { throw "AKS mesh enable failed" }

 Write-Step "Enabling Karpenter on AKS cluster..."
# az extension add --name aks-preview
# if ($LASTEXITCODE -ne 0) { throw "Failed to add aks-preview extension" }

# az feature register --namespace "Microsoft.ContainerService" --name "NodeAutoProvisioningPreview"
# if ($LASTEXITCODE -ne 0) { throw "Failed to register NodeAutoProvisioningPreview feature" }

# az provider register --namespace Microsoft.ContainerService
# if ($LASTEXITCODE -ne 0) { throw "Failed to register Microsoft.ContainerService provider" }

# az aks update --resource-group $ResourceGroup --name $ClusterName --node-provisioning-mode Auto --network-plugin-mode overlay
# if ($LASTEXITCODE -ne 0) { throw "Failed to enable Karpenter on AKS" }

# Write-Info "AKS deployment completed successfully!"
# Write-Host ""

# =====================================================
# 3. Deploy PostgreSQL
# =====================================================
Write-Info "================================================"
Write-Info "Starting PostgreSQL Deployment..."
Write-Info "================================================"
Set-Location (Join-Path $ScriptDir "4-postgresql")

Write-Step "Initializing Terraform for PostgreSQL..."
terraform init -reconfigure "-backend-config=$EnvDir\postgresql-backend.tfvars" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "PostgreSQL initialization failed" }

Write-Step "Planning PostgreSQL deployment..."
$varFile = Join-Path $EnvDir "postgresql.tfvars"
terraform plan -var-file $varFile -out postgresql.tfplan
if ($LASTEXITCODE -ne 0) { throw "PostgreSQL planning failed" }

Write-Step "Applying PostgreSQL deployment..."
terraform apply postgresql.tfplan
if ($LASTEXITCODE -ne 0) { throw "PostgreSQL apply failed" }

Write-Info "PostgreSQL deployment completed successfully!"
Write-Host ""

# =====================================================
# Deployment Complete
# =====================================================
Write-Info "================================================"
Write-Info "All infrastructure deployed successfully!"
Write-Info "================================================"
Write-Host ""
Write-Info "Next steps:"
Write-Host "  1. Configure kubectl: az aks get-credentials --resource-group rg-aks-dev --name aks-aks-dev-australiaeast"
Write-Host "  2. Verify cluster access: kubectl get nodes"
Write-Host "  3. Get PostgreSQL connection details from outputs"

# Return to original directory
Set-Location $ScriptDir
