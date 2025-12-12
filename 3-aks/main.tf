# =====================================================
# Production AKS with Azure Verified Modules (AVM)
# =====================================================

provider "azurerm" {
  subscription_id = var.subscription_id
  
  # Use Azure AD authentication for storage accounts
  storage_use_azuread = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =====================================================
# Resource Group
# =====================================================

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Network configuration from foundation
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = var.backend_storage_account_name
    container_name       = "tfstate"
    key                  = "network.tfstate"
    use_azuread_auth     = true
  }
}

# Production-ready AKS cluster with AVM
module "aks_cluster" {
  source  = "Azure/avm-ptn-aks-production/azurerm"
  version = "~> 0.1"

  # Core configuration
  name                = var.name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  kubernetes_version  = var.kubernetes_version

  # Network with CNI Overlay
  network = {
    node_subnet_id = data.terraform_remote_state.network.outputs.network_config.subnet_aks_system_id
    pod_cidr       = var.pod_cidr
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }
  network_policy = var.network_policy

  # Node pools
  default_node_pool_vm_sku = var.vm_size
  node_pools               = var.node_pools

  # Private cluster with Azure AD
  private_dns_zone_id         = var.private_cluster_enabled ? data.terraform_remote_state.network.outputs.network_config.private_dns_zone_aks_id : null
  private_dns_zone_id_enabled = var.private_cluster_enabled
  rbac_aad_tenant_id          = data.azurerm_client_config.current.tenant_id
  rbac_aad_azure_rbac_enabled = true

  # Use system-assigned identity for public cluster, user-assigned for private
  managed_identities = {
    system_assigned = !var.private_cluster_enabled
  }

  # Optional: Container Registry
  acr = var.enable_acr ? {
    name                          = var.acr_name
    subnet_resource_id            = data.terraform_remote_state.network.outputs.network_config.subnet_private_endpoints_id
    private_dns_zone_resource_ids = [data.terraform_remote_state.network.outputs.network_config.private_dns_zone_acr_id]
  } : null

  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

# =====================================================
# RBAC - Assign Azure Kubernetes Service RBAC Admin to user
# =====================================================

resource "azurerm_role_assignment" "aks_rbac_admin" {
  scope                = module.aks_cluster.resource_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =====================================================
# Kubernetes Provider Configuration
# =====================================================
# Note: Namespace creation commented out due to Azure AD auth requirements
# Create namespaces manually after cluster deployment using kubectl

# data "azurerm_kubernetes_cluster" "credentials" {
#   name                = "aks-${var.name}"
#   resource_group_name = azurerm_resource_group.aks.name

#   depends_on = [module.aks_cluster, azurerm_role_assignment.aks_rbac_admin]
# }

# provider "kubernetes" {
#   host                   = data.azurerm_kubernetes_cluster.credentials.kube_config[0].host
#   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config[0].client_certificate)
#   client_key             = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config[0].client_key)
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config[0].cluster_ca_certificate)
# }

# =====================================================
# Kubernetes Namespaces
# =====================================================
# Commented out - create manually using kubectl after cluster deployment:
# az aks get-credentials --resource-group <rg> --name <cluster>
# kubectl create namespace development
# kubectl create namespace staging

# resource "kubernetes_namespace" "namespaces" {
#   for_each = { for ns in var.namespaces : ns.name => ns }

#   metadata {
#     name   = each.value.name
#     labels = merge(
#       each.value.labels,
#       {
#         "managed-by" = "terraform"
#       }
#     )
#   }

#   depends_on = [module.aks_cluster]
# }
