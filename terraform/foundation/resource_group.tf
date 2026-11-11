# =============================================================================
# Resource group
#
# Pluralsight-style sandboxes provide a single pre-existing resource group,
# pass its name via var.resource_group_name and this module will reference
# it instead of creating one. Leave var.resource_group_name as null (the
# default) to have this module create a resource group following the
# naming convention.
# =============================================================================

locals {
  create_resource_group = var.resource_group_name == null
}

resource "azurerm_resource_group" "this" {
  count = local.create_resource_group ? 1 : 0

  name     = local.names.resource_group
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "existing" {
  count = local.create_resource_group ? 0 : 1

  name = var.resource_group_name
}

locals {
  resource_group_name = local.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_id   = local.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id

  # If we're given an existing resource group, deploy into its location
  # rather than var.location, so the two can't disagree.
  rg_location = local.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location
}
