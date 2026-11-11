provider "azurerm" {
  features {
    resource_group {
      # Pluralsight sandboxes pre-create one resource group and will not let
      # Terraform delete it on `destroy` even if it's empty. This avoids a
      # destroy-time error in that case. If you're creating your own RG
      # (resource_group_name = null), this has no effect.
      prevent_deletion_if_contains_resources = false
    }
  }
}
