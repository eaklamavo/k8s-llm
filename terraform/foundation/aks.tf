# =============================================================================
# AKS cluster
#
# Uses the native azurerm_kubernetes_cluster / azurerm_kubernetes_cluster_node_pool
# resources rather than the AKS AVM resource module. That module is still
# pre-1.0, has an open issue against the current AzureRM API version for
# agent pool security settings, and its node-pool variable shape has changed
# recently between versions. The native resources are stable and exactly
# documented, which matters more for a demo you'll run live than using AVM
# for AVM's sake. The VNet above does use the AVM module, where the interface
# is solid.
# =============================================================================

resource "azurerm_kubernetes_cluster" "this" {
  name                = local.names.aks
  resource_group_name = local.resource_group_name
  location            = local.rg_location
  dns_prefix          = local.names.aks
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "system"
    vm_size              = var.system_node_pool.vm_size
    vnet_subnet_id       = module.vnet.subnets["aks"].resource_id
    auto_scaling_enabled = true
    node_count           = var.system_node_pool.node_count
    min_count            = var.system_node_pool.min_count
    max_count            = var.system_node_pool.max_count
  }

  identity {
    type = "SystemAssigned"
  }

  # Azure CNI Overlay: nodes use the VNet subnet, pods get IPs from the
  # overlay CIDR below. This keeps the node subnet small regardless of how
  # many pods run per node.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.100.0.0/16"
    dns_service_ip      = "10.100.0.10"
  }

  # Enables the Azure Key Vault Provider for Secrets Store CSI Driver addon.
  # AKS creates a dedicated managed identity for it, exposed below as
  # key_vault_secrets_provider[0].secret_identity[0], which keyvault.tf
  # grants read access to the Key Vault.
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# GPU node pool for model serving (vLLM)
#
# Tainted so only pods that explicitly tolerate nvidia.com/gpu land here.
# AKS auto-installs the NVIDIA driver and device plugin for this SKU on
# Ubuntu nodes, once the node is Ready, `kubectl describe node <gpu-node>`
# should show nvidia.com/gpu in Allocatable.
# -----------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count = var.gpu_node_pool_enabled ? 1 : 0

  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.gpu_node_pool.vm_size
  vnet_subnet_id        = module.vnet.subnets["aks"].resource_id
  os_sku                = "Ubuntu"
  mode                  = "User"

  auto_scaling_enabled = true
  min_count            = var.gpu_node_pool.min_count
  max_count            = var.gpu_node_pool.max_count
  # Initial count: keep at least one GPU node warm so the vLLM demo doesn't
  # wait 5-10 minutes for a node to provision live. Set min_count = 0 and
  # this to 0 if you want to demonstrate scale-from-zero instead.
  node_count = max(var.gpu_node_pool.min_count, 1)

  node_taints = [
    "nvidia.com/gpu=present:NoSchedule"
  ]

  node_labels = {
    workload = "gpu"
  }

  tags = var.tags
}
