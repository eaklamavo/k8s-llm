# =============================================================================
# Naming convention
#
# Resource names are built as: {resource-type}-{project}-{landscape}-{region}-{sequence}
# Subnets add a {purpose} segment: snet-{project}-{purpose}-{landscape}-{region}-{sequence}
#
# Example: rg-cnandk8s-sbox-uks-01, vnet-cnandk8s-sbox-uks-01,
#          snet-cnandk8s-k8snodes-sbox-uks-01
# =============================================================================

variable "project" {
  description = "Project short name, used as the {project} segment in resource names."
  type        = string
  default     = "cnandk8s"
}

variable "landscape" {
  description = "Environment/landscape short name, e.g. sbox, dev, qa, pprod, prod."
  type        = string
  default     = "sbox"
}

variable "region_code" {
  description = "Short region code used in resource names, e.g. uks, ukw, useast."
  type        = string
  default     = "uks"
}

variable "sequence" {
  description = "Sequence number segment, e.g. 01, 02."
  type        = string
  default     = "01"
}

variable "location" {
  description = "Full Azure region name resources are deployed into, e.g. uksouth, eastus. Only used when this module creates the resource group, an existing resource group's own location otherwise takes precedence."
  type        = string
  default     = "uksouth"
}

# =============================================================================
# Resource group
# =============================================================================

variable "resource_group_name" {
  description = "Name of an existing resource group to deploy into (e.g. the one provided by a Pluralsight sandbox). Leave as null to create a new resource group using the naming convention above."
  type        = string
  default     = null
}

# =============================================================================
# Networking
# =============================================================================

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. The map key is a short logical name used to
    reference the subnet elsewhere in this module (the AKS node pools below
    expect a key called "aks"). `purpose` feeds the {purpose} segment of the
    subnet naming convention (e.g. k8snodes, shared, dns, privatedns, resolver).
  EOT
  type = map(object({
    purpose          = string
    address_prefixes = list(string)
  }))
  default = {
    aks = {
      purpose          = "k8snodes"
      address_prefixes = ["10.20.0.0/22"]
    }
  }
}

# =============================================================================
# AKS
# =============================================================================

variable "kubernetes_version" {
  description = "Kubernetes minor version, e.g. \"1.30\". Leave null to use AKS's current default."
  type        = string
  default     = null
}

variable "system_node_pool" {
  description = "Sizing for the default (system) node pool. Resize the cluster by changing these values."
  type = object({
    vm_size    = string
    node_count = optional(number, 2)
    min_count  = optional(number, 1)
    max_count  = optional(number, 3)
  })
  default = {
    vm_size    = "Standard_D4s_v5"
    node_count = 2
    min_count  = 1
    max_count  = 3
  }
}

variable "gpu_node_pool" {
  description = "Sizing for the GPU node pool used for model serving (vLLM). Change vm_size here to switch GPU SKU."
  type = object({
    vm_size   = string
    min_count = optional(number, 0)
    max_count = optional(number, 2)
  })
  default = {
    vm_size   = "Standard_NC4as_T4_v3"
    min_count = 0
    max_count = 2
  }
}

variable "gpu_node_pool_enabled" {
  description = "Set to false to skip the GPU node pool entirely, e.g. if the subscription has no GPU quota. The CPU-only Ollama example still works without it."
  type        = bool
  default     = true
}

# =============================================================================
# Flux / GitOps bootstrap
# =============================================================================

variable "flux_git_repository_url" {
  description = "SSH URL of the private repo Flux bootstraps from, e.g. git@github.com:your-org/your-repo.git"
  type        = string
}

variable "flux_git_branch" {
  description = "Branch Flux tracks."
  type        = string
  default     = "main"
}

variable "flux_bootstrap_path" {
  description = "Path within the repo that Flux reconciles first (this is expected to contain the ArgoCD HelmRelease)."
  type        = string
  default     = "./bootstrap"
}

variable "flux_git_ssh_private_key_base64" {
  description = "Base64-encoded SSH private key (read-only deploy key) for the Flux git source. Pass this via the TF_VAR_flux_git_ssh_private_key_base64 environment variable, never commit it."
  type        = string
  sensitive   = true
}

# =============================================================================
# Key Vault
# =============================================================================

variable "key_vault_name" {
  description = "Optional explicit Key Vault name. Key Vault names must be globally unique and 3-24 characters, so if left null a shortened name with a random suffix is generated instead of the full naming-convention name."
  type        = string
  default     = null
}

variable "key_vault_sku" {
  description = "Key Vault SKU: standard or premium."
  type        = string
  default     = "standard"
}

# =============================================================================
# Tagging
# =============================================================================

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
