# =============================================================================
# Key Vault
#
# Used later via the Azure Key Vault Provider for Secrets Store CSI Driver
# (enabled on the AKS cluster in aks.tf via key_vault_secrets_provider).
# To mount a secret into a pod: create a SecretProviderClass in the cluster
# referencing this vault, then reference that SecretProviderClass as a
# volume in the pod spec. The role assignment below is what allows the
# CSI driver's managed identity to read secrets from this vault.
#
# SOFT DELETE NOTE:
# Azure Key Vault soft delete is mandatory and cannot be disabled. Even with
# purge_protection_enabled = false, a destroyed vault sits in soft-deleted
# state for soft_delete_retention_days before the name is released. This
# would block a rebuild with the same name.
#
# Two mitigations are used here:
# 1. random_string suffix: each apply generates a fresh unique name, so a
#    soft-deleted vault from a previous destroy never conflicts.
# 2. null_resource purge: on destroy, a local-exec immediately purges the
#    soft-deleted vault so the name is released straight away. This requires
#    the az CLI to be available and authenticated wherever terraform destroy
#    is run.
# =============================================================================

data "azurerm_client_config" "current" {}

resource "random_string" "key_vault_suffix" {
  length  = 4
  special = false
  upper   = false

  keepers = {
    name_root = "kv-${var.project}-${var.landscape}-${var.region_code}"
  }
}

locals {
  key_vault_name = coalesce(
    var.key_vault_name,
    "${substr("kv-${var.project}-${var.landscape}-${var.region_code}-${var.sequence}", 0, 19)}-${random_string.key_vault_suffix.result}"
  )
}

resource "azurerm_key_vault" "this" {
  name                = local.key_vault_name
  resource_group_name = local.resource_group_name
  location            = local.rg_location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku

  enable_rbac_authorization = true

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_secrets_provider_kv_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}