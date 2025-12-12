# Azure AKS Platform with AVM

Production-grade Azure Kubernetes Service deployment using **Azure Verified Modules (AVM)**.

## Architecture

```
Modular Azure Platform Structure
│
├─ 0-bootstrap/              # One-time: Terraform state storage (minimal)
│   └─ Creates: Storage Account with AVM
│
├─ 1-subscription-vending/   # Platform team: Landing zone provisioning
│   └─ Creates: Subscriptions, VNets, RBAC, Budgets (AVM)
│
├─ 2-network/                # Network team: Network infrastructure
│   └─ Creates: VNet, Subnets, DNS Zones, Identities (AVM)
│
├─ 3-aks/                    # Platform team: Kubernetes cluster
│   └─ Creates: AKS Cluster, ACR, Monitoring (AVM)
│
└─ 4-postgresql/             # Data team: PostgreSQL database
    └─ Creates: PostgreSQL Flexible Server (AVM)
```

##  Responsibilities

| Module | Resources |
|--------|-----------|
| **0-bootstrap** | Terraform state storage (one-time) |
| **1-subscription-vending** | Subscriptions, Landing Zones, RBAC |
| **2-network** |  VNet, Subnets, DNS, Identities |
| **3-aks** |  AKS Cluster, ACR, Monitoring |
| **4-postgresql** | PostgreSQL Flexible Server, Databases |

## Deployment Order

### Step 1: Bootstrap (One-time per environment)
```bash
cd 0-bootstrap
terraform init
terraform apply -var="environment=dev"
```

### Step 2: Subscription Vending (Platform Team)
```bash
cd 1-subscription-vending
terraform init
terraform apply -var-file=terraform.tfvars
```
### Step 3: Network 
```bash
cd 2-network
terraform init -backend-config=environments/dev/network-backend.tfvars
terraform apply -var-file=environments/dev/network.tfvars
```

### Step 4: AKS 
```bash
cd 3-aks
terraform init -backend-config=environments/dev/aks-backend.tfvars
terraform apply -var-file=environments/dev/aks.tfvars
```

### Step 5: PostgreSQL 
```bash
cd 4-postgresql
terraform init -backend-config=environments/dev/backend.tfvars
terraform apply -var-file=environments/dev/postgresql.tfvars
```


## Why Azure Verified Modules (AVM)?

All modules in this repository use **Azure Verified Modules** - Microsoft's official IaC module standard:

✅ **Microsoft Supported**: Officially maintained and supported by Microsoft
✅ **Well-Architected**: Built following Azure Well-Architected Framework best practices
✅ **Production Ready**: Battle-tested modules with comprehensive examples
✅ **Consistent Interface**: Standardized parameters and outputs across all modules
✅ **Security Focused**: Built-in security controls and compliance features
✅ **Regular Updates**: Kept current with latest Azure services and features

## Features

### 0-bootstrap
- **Minimal bootstrap** using AVM Storage Account Module
- Geo-redundant storage (GRS)
- State encryption and blob versioning
- One-time setup per environment

### 1-subscription-vending
- **AVM Landing Zone Vending Pattern Module**
- Automated subscription creation (EA/MCA)
- Management group association
- Virtual network with hub peering
- Role assignments and RBAC
- Resource group provisioning
- Budget and cost management

### 2-network
- **AVM Virtual Network Module** with integrated subnets
- Virtual Network with planned CIDR ranges
- Subnets for AKS nodes and private endpoints
- Private DNS zones (AKS, ACR)
- User-assigned managed identities
- Role assignments

### 3-aks
- **AVM AKS Production Pattern Module**
- Private AKS cluster with CNI Overlay
- **Ubuntu OS** for node pools
- Remote state integration with 2-network module
- Multi-zone node pools with autoscaling
- Azure Container Registry (optional, private)
- Log Analytics and Azure Monitor
- Azure Policy and Workload Identity (OIDC)

### 4-postgresql
- **AVM PostgreSQL Flexible Server Module**
- Private endpoint integration with VNet
- Entra ID (Azure AD) authentication support
- High availability (zone-redundant option)
- Configurable databases and collations
- Automated backups with geo-redundancy option
- Auto-generated secure admin password

## Multi-Region Support

```
Australia East (Primary)     Australia Southeast (DR)
├─ foundation-aue            ├─ foundation-ase
├─ aks-prod-aue              ├─ aks-prod-ase
└─ ACR with geo-replication  └─ ACR replica
```

## State Management

Each module uses Azure Storage backend:

```
Storage Account: sttfstate{env}
├─ Container: tfstate
    ├─ bootstrap/terraform.tfstate
    ├─ foundation/{env}/terraform.tfstate
    └─ aks/{env}/terraform.tfstate
```

## Benefits

✅ **Separation of Concerns**: Network ≠ Platform ≠ Application
✅ **Team Autonomy**: Independent deployments
✅ **Change Control**: Granular approval workflows
✅ **Disaster Recovery**: Regional independence
✅ **Compliance**: Full audit trail
✅ **Multi-Cloud Ready**: Consistent patterns

## Quick Start

See detailed guides in each module:
- [0-bootstrap/README.md](0-bootstrap/README.md)
- [1-subscription-vending/README.md](1-subscription-vending/README.md)
- [2-network/README.md](2-network/README.md)
- [3-aks/README.md](3-aks/README.md)
- [4-postgresql/README.md](4-postgresql/README.md)

## Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture decisions
- [ENVIRONMENTS.md](ENVIRONMENTS.md) - Environment strategy

## Support

For enterprise support, contact the Platform Engineering team.
