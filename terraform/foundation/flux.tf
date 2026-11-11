# =============================================================================
# Flux GitOps bootstrap
#
# Installs the AKS "microsoft.flux" cluster extension, then configures it to
# reconcile var.flux_bootstrap_path from the private repo. That path is
# expected to contain a HelmRelease installing ArgoCD; from there, ArgoCD
# takes over via the ApplicationSet(s) in the repo's gitops/ tree.
#
# Known issue: the microsoft.flux extension can take 10-30 minutes to apply
# (and occasionally to destroy) via Terraform. The generous timeouts below
# are deliberate, expect this step to be the slowest part of `terraform apply`.
# =============================================================================

resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = local.names.flux_extension
  cluster_id     = azurerm_kubernetes_cluster.this.id
  extension_type = "microsoft.flux"

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "azurerm_kubernetes_flux_configuration" "bootstrap" {
  name       = local.names.flux_config
  cluster_id = azurerm_kubernetes_cluster.this.id
  namespace  = "flux-system"

  git_repository {
    url                     = var.flux_git_repository_url
    reference_type          = "branch"
    reference_value         = var.flux_git_branch
    ssh_private_key_base64  = var.flux_git_ssh_private_key_base64
  }

  kustomizations {
    name = "bootstrap"
    path = var.flux_bootstrap_path
  }

  depends_on = [azurerm_kubernetes_cluster_extension.flux]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
