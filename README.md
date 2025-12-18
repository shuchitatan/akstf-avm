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

> **📖 For detailed step-by-step instructions, see [DEPLOYMENT-FLOW.md](DEPLOYMENT-FLOW.md)**  
> Each module has its own README with prerequisites, configuration, and commands.

| Step | Module | Purpose |
|------|--------|---------|
| 1 | [0-bootstrap](0-bootstrap/README.md) | Create Terraform state storage (one-time) |
| 2 | [1-subscription-vending](1-subscription-vending/README.md) | *(Optional)* Create/configure subscriptions |
| 3 | [2-network](2-network/README.md) | Deploy VNet, subnets, DNS zones, identities |
| 4 | [3-aks](3-aks/README.md) | Deploy AKS cluster and ACR |
| 5 | [4-postgresql](4-postgresql/README.md) | Deploy PostgreSQL Flexible Server |


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

## Documentation

- [DEPLOYMENT-FLOW.md](DEPLOYMENT-FLOW.md) - Visual deployment flow & architecture diagrams
- [STRUCTURE.md](STRUCTURE.md) - Repository structure

## Support

For enterprise support, contact the Platform Engineering team.
