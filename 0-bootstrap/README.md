# Bootstrap Module

Creates the Azure Storage backend for Terraform remote state management using **Azure Verified Modules (AVM)**.

## Purpose

This module is run **ONCE** to set up the infrastructure needed for storing Terraform state files remotely. All subsequent modules (network, AKS, PostgreSQL) will use this storage backend.

## What It Creates

Using the **AVM Storage Account Module** (`Azure/avm-res-storage-storageaccount/azurerm`):

- Resource Group: `rg-terraform-state`
- Storage Account: `sttfstate{environment}` with AVM best practices
- Storage Container: `tfstate` (created within AVM module)
- Blob versioning and soft delete (30-day retention)
- Geo-redundant storage (GRS) for disaster recovery
- Infrastructure encryption enabled
- TLS 1.2 minimum, HTTPS-only traffic
- No public blob access

## Prerequisites

- Azure CLI authenticated
- Appropriate Azure subscription permissions
- Terraform >= 1.9 installed

## Deployment

### Step 1: Set Environment Variables

```bash
cd 0-bootstrap
```

**Bash (Linux/macOS/Git Bash):**
```bash
# Set your Azure Subscription ID
export TF_VAR_subscription_id="00000000-0000-0000-0000-000000000000"

# For development
export TF_VAR_environment="dev"

# For production
export TF_VAR_environment="prod"
```

**PowerShell (Windows):**
```powershell
# Set your Azure Subscription ID
$env:TF_VAR_subscription_id = "00000000-0000-0000-0000-000000000000"

# For development
$env:TF_VAR_environment = "dev"

# For production
$env:TF_VAR_environment = "prod"
```

### Step 2: Initialize and Apply

```bash
# Initialize (uses LOCAL backend)
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

### Step 3: Save Outputs

```bash
# Get backend configuration for other modules
terraform output backend_config

# Example output:
# resource_group_name  = "rg-terraform-state"
# storage_account_name = "sttfstatedev"
# container_name       = "tfstate"
```

## Usage in Other Modules

After bootstrap is complete, use the outputs to update the backend configuration files in `environments/dev/`:

### environments/dev/backend.tfvars (for 2-network)
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatedevXXXXXX"
container_name       = "tfstate"
key                  = "network.tfstate"
use_azuread_auth     = true
```

### environments/dev/aks-backend.tfvars (for 3-aks)
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatedevXXXXXX"
container_name       = "tfstate"
key                  = "aks.tfstate"
use_azuread_auth     = true
```

### environments/dev/postgresql-backend.tfvars (for 4-postgresql)
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatedevXXXXXX"
container_name       = "tfstate"
key                  = "postgresql.tfstate"
use_azuread_auth     = true
```

## State Storage Strategy

```
Storage Account: sttfstatedevXXXXXX
└── Container: tfstate
    ├── network.tfstate      (2-network module)
    ├── aks.tfstate          (3-aks module)
    └── postgresql.tfstate   (4-postgresql module)

Note: 0-bootstrap uses local state, 1-subscription-vending doesn't use remote state.
```

## Security Features

- ✅ HTTPS only traffic
- ✅ TLS 1.2 minimum
- ✅ No public blob access
- ✅ Infrastructure encryption
- ✅ Blob versioning enabled
- ✅ Soft delete (30 days)
- ✅ Geo-redundant storage (GRS)

## Disaster Recovery

The storage account uses **Geo-Redundant Storage (GRS)**, which:
- Replicates data to a secondary region
- Provides 99.99999999999999% (16 9's) durability
- Enables recovery if primary region fails

## Cleanup

**⚠️ WARNING**: Only delete if you want to destroy ALL Terraform-managed infrastructure.

```bash
terraform destroy
```

This will delete:
- All Terraform state files
- The storage account
- The resource group

## Troubleshooting

### Issue: Storage account name already exists

Storage account names must be globally unique. If the name is taken, change the environment variable:

**Bash:**
```bash
export TF_VAR_environment="dev2"
```

**PowerShell:**
```powershell
$env:TF_VAR_environment = "dev2"
```

Or customize in terraform.tfvars.

### Issue: Permission denied

Ensure you have:
- Contributor role on the subscription
- Ability to create resource groups
- Ability to create storage accounts

## Next Steps

After bootstrap is complete:
1. ✅ Note the storage account name from outputs
2. ✅ Update `environments/dev/backend.tfvars` files with the storage account name
3. ✅ Proceed to [1-subscription-vending](../1-subscription-vending/README.md) or [2-network](../2-network/README.md)
