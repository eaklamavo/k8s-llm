# =============================================================================
# Naming convention locals
#
# {resource-type}-{project}-{landscape}-{region}-{sequence}
# subnets:  snet-{project}-{purpose}-{landscape}-{region}-{sequence}
# =============================================================================

locals {
  name_suffix = "${var.project}-${var.landscape}-${var.region_code}-${var.sequence}"

  names = {
    resource_group = "rg-${local.name_suffix}"
    vnet           = "vnet-${local.name_suffix}"
    aks            = "aks-${local.name_suffix}"
    flux_extension = "flux-${local.name_suffix}"
    flux_config    = "fc-${local.name_suffix}"
  }

  # snet-{project}-{purpose}-{landscape}-{region}-{sequence}
  subnet_names = {
    for key, subnet in var.subnets :
    key => "snet-${var.project}-${subnet.purpose}-${var.landscape}-${var.region_code}-${var.sequence}"
  }
}
