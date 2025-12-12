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

### Step 1: Create Configuration File

```bash
cd environments/dev

# Copy the example file
cp bootstrap.tfvars.example bootstrap.tfvars

# Edit with your values
# - Set your subscription_id
# - Set environment (dev or prod)
```

### Step 2: Initialize and Apply

**Bash (Linux/macOS/Git Bash):**
```bash
cd 0-bootstrap

# Initialize (uses LOCAL backend)
terraform init

# Plan
terraform plan -var-file="../environments/dev/bootstrap.tfvars"

# Apply
terraform apply -var-file="../environments/dev/bootstrap.tfvars"
```

**PowerShell (Windows):**
```powershell
cd 0-bootstrap

# Initialize (uses LOCAL backend)
terraform init

# Plan
terraform plan -var-file="..\environments\dev\bootstrap.tfvars"

# Apply
terraform apply -var-file="..\environments\dev\bootstrap.tfvars"
```

### Step 3: Save Outputs

```bash
# Get storage account name for other modules
terraform output storage_account_name

# Get full backend configuration
terraform output backend_config
```

## Usage in Other Modules

After bootstrap is complete, copy the `.tfvars.example` files and update with your values:

### For 2-network
```bash
cd ../environments/dev
cp network-backend.tfvars.example network-backend.tfvars
cp network.tfvars.example network.tfvars
# Edit both files with your storage_account_name and subscription_id
```

### For 3-aks
```bash
cp aks-backend.tfvars.example aks-backend.tfvars
cp aks.tfvars.example aks.tfvars
# Edit both files with your storage_account_name and subscription_id
```

### For 4-postgresql
```bash
cp postgresql-backend.tfvars.example postgresql-backend.tfvars
cp postgresql.tfvars.example postgresql.tfvars
# Edit both files with your storage_account_name and subscription_id
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

Storage account names must be globally unique. If the name is taken, change the environment in your `bootstrap.tfvars`:

```hcl
environment = "dev2"
```

### Issue: Permission denied

Ensure you have:
- Contributor role on the subscription
- Ability to create resource groups
- Ability to create storage accounts

## Next Steps

After bootstrap is complete:
1. ✅ Note the storage account name from outputs
2. ✅ Copy `.tfvars.example` files and update with your values
3. ✅ Proceed to [1-subscription-vending](../1-subscription-vending/README.md) or [2-network](../2-network/README.md)
