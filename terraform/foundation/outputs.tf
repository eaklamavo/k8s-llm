output "resource_group_name" {
  description = "Name of the resource group resources were deployed into."
  value       = local.resource_group_name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_get_credentials_command" {
  description = "Run this to configure kubectl against the cluster."
  value       = "az aks get-credentials --resource-group ${local.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name} --overwrite-existing"
}

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.vnet.resource_id
}

output "gpu_node_pool_enabled" {
  description = "Whether the GPU node pool was created."
  value       = var.gpu_node_pool_enabled
}

output "key_vault_name" {
  description = "Name of the Key Vault for the Secrets Store CSI driver."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault, used in SecretProviderClass manifests."
  value       = azurerm_key_vault.this.vault_uri
}

output "flux_configuration_id" {
  description = "Resource ID of the Flux configuration."
  value       = azurerm_kubernetes_flux_configuration.bootstrap.id
}
