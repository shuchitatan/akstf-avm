# AKS Deployment Flow

## Overview
This repository deploys a production-ready Azure Kubernetes Service (AKS) cluster using a modular, sequential approach with Terraform remote state management.

> **📖 For step-by-step deployment instructions, see each module's README.**  
> This document provides a visual overview of the deployment flow and architecture.

---

## Deployment Flowchart

```mermaid
flowchart TD
    Start([Start Deployment]) --> Bootstrap
    
    subgraph Bootstrap["0-bootstrap"]
        B1[Initialize local backend]
        B2[Create Resource Group<br/>rg-terraform-state]
        B3[Create Storage Account<br/>sttfstatedev******]
        B4[Create Blob Container<br/>tfstate]
        B5[Configure Entra ID Auth<br/>with versioning enabled]
        B1 --> B2 --> B3 --> B4 --> B5
    end
    
    Bootstrap --> |"Outputs:<br/>storage_account_name"| SubVending
    
    subgraph SubVending["1-subscription-vending (Optional)"]
        SV1[Create new subscription<br/>OR use existing]
        SV2[Apply governance<br/>Management Groups, RBAC]
        SV3[Configure budgets]
        SV1 --> SV2 --> SV3
    end
    
    SubVending --> |"Outputs:<br/>subscription_id"| Network
    
    subgraph Network["2-network"]
        N1[Configure remote backend<br/>backend.tfvars]
        N2[Assign Storage Blob<br/>Data Contributor role]
        N3[terraform init with<br/>Azure AD auth]
        N4[Create VNet + Subnets<br/>10.0.0.0/16]
        N5[Create Private DNS Zones<br/>AKS & ACR]
        N6[Create Managed Identity<br/>for AKS]
        N7[Configure NSG]
        N1 --> N2 --> N3 --> N4 --> N5 --> N6 --> N7
    end
    
    Network --> |"State: network.tfstate<br/>Outputs: network_config"| AKS
    
    subgraph AKS["3-aks"]
        A1[Read network state<br/>via remote_state]
        A2[Enable subscription features<br/>EncryptionAtHost]
        A3[Create Resource Group<br/>rg-aks01-baseline-dev]
        A4[Deploy AKS Cluster<br/>v1.31 + Cilium via AVM]
        A5[Configure Private Cluster<br/>with Azure AD RBAC]
        A6[Create Default Node Pool<br/>Standard_D4d_v5]
        A7[Optional: User Node Pools<br/>via node_pools variable]
        A8[Create ACR with<br/>Private Endpoint]
        A9[Assign RBAC Cluster Admin]
        A1 --> A2 --> A3 --> A4 --> A5 --> A6 --> A7 --> A8 --> A9
    end
    
    AKS --> |"State: aks.tfstate"| PostgreSQL
    
    subgraph PostgreSQL["4-postgresql"]
        P1[Read network state]
        P2[Create PostgreSQL<br/>Flexible Server]
        P3[Configure VNet Integration<br/>& Private DNS Zone]
        P1 --> P2 --> P3
    end
    
    PostgreSQL --> Complete([Deployment Complete])
    
    Complete --> Access
    
    subgraph Access["Access Cluster"]
        AC1[az aks get-credentials]
        AC2[kubectl get nodes]
    end
    
    style Bootstrap fill:#e1f5ff
    style SubVending fill:#f3e5f5
    style Network fill:#fff4e1
    style AKS fill:#e8f5e9
    style PostgreSQL fill:#f8bbd0
    style Access fill:#f3e5f5
```

---

## Deployment Phases

### Phase 1: Bootstrap (0-bootstrap)
**Purpose**: Create remote state storage for all modules

**Creates**:
- Resource Group: `rg-terraform-state`
- Storage Account: `sttfstatedevXXXXXX` (random suffix)
  - GRS replication
  - Blob versioning enabled
  - 30-day delete retention
- Container: `tfstate`
- Azure AD (Entra ID) authentication configured

**Outputs**: `storage_account_name` → Used by all subsequent modules

📖 **[Full instructions → 0-bootstrap/README.md](0-bootstrap/README.md)**

---

### Phase 2: Subscription Vending (1-subscription-vending) - OPTIONAL
**Purpose**: Create or configure Azure subscriptions with governance

> **Skip this phase** if you already have a subscription to use.

**Creates** (if creating new subscription):
- New Azure Subscription
- Management Group association
- Role assignments
- Budgets

**Outputs**: `subscription_id` → Can be used by subsequent modules

📖 **[Full instructions → 1-subscription-vending/README.md](1-subscription-vending/README.md)**

---

### Phase 3: Network Foundation (2-network)
**Purpose**: Create network infrastructure and prerequisites

**Creates**:
- Resource Group: `rg-aks-network-dev`
- Virtual Network: `vnet-aks-dev` (10.0.0.0/16)
- Subnets:
  - `snet-aks-system` (10.0.0.0/22)
  - `snet-private-endpoints` (10.0.4.0/24)
- Private DNS Zones:
  - `privatelink.australiaeast.azmk8s.io`
  - `privatelink.azurecr.io`
- Managed Identity: `id-aks-dev`
- Network Security Group (optional)

**State File**: `tfstate/network.tfstate`

**Outputs** → `network_config`: VNet ID, Subnet IDs, DNS Zone IDs, Managed Identity

📖 **[Full instructions → 2-network/README.md](2-network/README.md)**

---

### Phase 4: AKS Deployment (3-aks)
**Purpose**: Deploy production AKS cluster using Azure Verified Modules

**Reads Remote State**: `network.tfstate` → Gets VNet, subnets, DNS zones, identity

**Creates**:
- Resource Group: `rg-aks01-baseline-dev`
- AKS Cluster: `aks01-baseline-dev`
  - Kubernetes: v1.31
  - Network Policy: Cilium
  - CNI: Azure Overlay (pods: 10.244.0.0/16)
  - Service CIDR: 10.245.0.0/16
  - Private Cluster: enabled
- Node Pools:
  - Default: Standard_D4d_v5 (autoscaling via AVM module)
  - User: Optional, configured via `node_pools` variable
- Azure Container Registry: `acr01baselinedev` (with private endpoint)
- Role Assignments:
  - Azure Kubernetes Service RBAC Cluster Admin

**State File**: `tfstate/aks.tfstate`

**Outputs**: `cluster_id`, `cluster_name`, `cluster_fqdn`, `kube_config_raw`, `oidc_issuer_url`

📖 **[Full instructions → 3-aks/README.md](3-aks/README.md)**

---

### Phase 5: PostgreSQL Deployment (4-postgresql)
**Purpose**: Deploy PostgreSQL Flexible Server with VNet integration

**Reads Remote State**: `network.tfstate` → Gets VNet ID for Private DNS Zone linking

**Creates**:
- Resource Group (configurable via variable)
- PostgreSQL Flexible Server (AVM module)
  - Configurable SKU, storage, and version
  - Azure AD and/or password authentication
  - Optional high availability
  - Geo-redundant backup support
- Private DNS Zone: `privatelink.postgres.database.azure.com` (when using VNet integration)
- Private DNS Zone VNet Link

**State File**: `tfstate/postgresql.tfstate`

**Outputs**: `postgresql_id`, `postgresql_name`, `postgresql_fqdn`, `connection_string`

📖 **[Full instructions → 4-postgresql/README.md](4-postgresql/README.md)**

---

## State Management Flow

```mermaid
flowchart LR
    subgraph Storage["Azure Storage Account"]
        direction TB
        C1[Container: tfstate]
        S1[network.tfstate]
        S2[aks.tfstate]
        S3[postgresql.tfstate]
        C1 --> S1
        C1 --> S2
        C1 --> S3
    end
    
    N[2-network] -->|writes| S1
    A[3-aks] -->|reads| S1
    A -->|writes| S2
    P[4-postgresql] -->|reads| S1
    P -->|writes| S3
    
    style Storage fill:#e3f2fd
    style S1 fill:#fff9c4
    style S2 fill:#fff9c4
    style S3 fill:#fff9c4
```

---

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant AzureCLI
    participant Storage
    participant Terraform
    
    User->>AzureCLI: az login
    AzureCLI-->>User: Token
    
    User->>AzureCLI: Assign Storage Blob Data Contributor
    AzureCLI->>Storage: Create role assignment
    
    User->>Terraform: terraform init -backend-config
    Terraform->>Storage: Authenticate with Azure AD
    Storage-->>Terraform: Access granted
    
    User->>Terraform: terraform apply
    Terraform->>Storage: Read/write state with Azure AD auth
    Storage-->>Terraform: State data
```

---

## Configuration Files Structure

```
aksavm/
├── 0-bootstrap/
│   ├── main.tf              # Bootstrap resources
│   ├── variables.tf         # subscription_id, environment
│   └── terraform.tfstate    # LOCAL state only
│
├── 1-subscription-vending/  # OPTIONAL
│   ├── main.tf              # Subscription vending module
│   ├── variables.tf         # Subscription configuration
│   └── outputs.tf           # subscription_id output
│
├── 2-network/
│   ├── main.tf              # Network resources + AVM module
│   ├── variables.tf         # Network configuration
│   ├── versions.tf          # Backend: azurerm (remote)
│   └── outputs.tf           # network_config output
│
├── 3-aks/
│   ├── main.tf              # AKS + remote state data source
│   ├── variables.tf         # AKS configuration
│   ├── versions.tf          # Backend: azurerm (remote)
│   ├── locals.tf            # Azure client config
│   └── outputs.tf           # Cluster outputs
│
├── 4-postgresql/
│   ├── main.tf              # PostgreSQL Flexible Server
│   ├── variables.tf         # Database configuration
│   ├── versions.tf          # Backend: azurerm (remote)
│   └── outputs.tf           # Connection outputs
│
└── environments/
    └── dev/
        ├── backend.tfvars       # Backend config for 2-network
        ├── aks-backend.tfvars   # Backend config for 3-aks
        ├── postgresql-backend.tfvars  # Backend config for 4-postgresql
        ├── network.tfvars       # Network variables
        ├── aks.tfvars           # AKS variables
        └── postgresql.tfvars    # PostgreSQL variables
```

---

## Key Dependencies

```mermaid
graph TD
    B[0-bootstrap<br/>Storage Account] --> SV
    SV[1-subscription-vending<br/>Optional] --> N
    B --> N
    N[2-network<br/>VNet + DNS + Identity] --> A
    N --> P
    A[3-aks<br/>AKS Cluster + ACR]
    P[4-postgresql<br/>Database]
    
    B -.->|storage_account_name| N
    SV -.->|subscription_id| N
    N -.->|network_config| A
    N -.->|network_config| P
    
    style B fill:#bbdefb
    style SV fill:#f3e5f5
    style N fill:#fff9c4
    style A fill:#c8e6c9
    style P fill:#f8bbd0
```

---

## Variables Flow

### Bootstrap → Network
```
backend_config (from bootstrap output)
  ↓
environments/dev/backend.tfvars
  ↓
terraform init -backend-config
```

### Network → AKS
```
network.tfstate (remote state)
  ↓
data.terraform_remote_state.network
  ↓
outputs.network_config {
  subnet_aks_system_id
  private_dns_zone_aks_id
  identity_id
}
  ↓
module.aks_cluster inputs
```

---

## Troubleshooting Flow

```mermaid
flowchart TD
    E1{Error?} -->|Key-based auth<br/>not permitted| Fix1[Add storage_use_azuread = true<br/>to provider]
    E1 -->|403 Forbidden| Fix2[Assign Storage Blob<br/>Data Contributor role]
    E1 -->|State file not found| Fix3[Check state key path<br/>in remote_state config]
    E1 -->|K8s version not supported| Fix4[Update to supported version<br/>e.g., 1.31]
    E1 -->|EncryptionAtHost error| Fix5[Enable feature:<br/>az feature register]
    E1 -->|Identity not found| Fix6[Ensure network module<br/>deployed first]
    
    Fix1 --> Success([Retry])
    Fix2 --> Success
    Fix3 --> Success
    Fix4 --> Success
    Fix5 --> Success
    Fix6 --> Success
    
    style E1 fill:#ffebee
    style Success fill:#c8e6c9
```

---

## Summary

1. **Bootstrap (0-bootstrap)**: Creates shared remote state storage (run once)
2. **Subscription Vending (1-subscription-vending)**: Optional - creates/configures subscriptions
3. **Network (2-network)**: Creates foundation infrastructure, stores state remotely
4. **AKS (3-aks)**: Reads network state, deploys AKS cluster and optional ACR
5. **PostgreSQL (4-postgresql)**: Reads network state, deploys PostgreSQL Flexible Server with VNet integration
6. **Access**: Use Azure CLI to get kubeconfig and access cluster

All modules use Entra ID authentication for state storage (no access keys needed).
