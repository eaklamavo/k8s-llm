# =============================================================================
# Virtual network + subnets (AVM resource module)
#
# Pinned to exact version 0.18.0. The 0.18.x release changed
# resource_group_name -> parent_id (full resource group ID) and confirmed
# subnet output attribute is .resource_id.
#
# Exact pinning (not ~>) is intentional: this is a demo repo where
# reproducibility matters more than automatic updates. If you upgrade,
# do it deliberately, check the module's CHANGELOG, and re-test.
# =============================================================================

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.18.0"

  name          = local.names.vnet
  parent_id     = local.resource_group_id
  location      = local.rg_location
  address_space = var.vnet_address_space

  subnets = {
    for key, subnet in var.subnets :
    key => {
      name             = local.subnet_names[key]
      address_prefixes = subnet.address_prefixes
    }
  }

  tags = var.tags
}
