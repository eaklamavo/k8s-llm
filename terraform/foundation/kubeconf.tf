provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_cluster_role_binding_v1" "flux_applier_cluster_admin" {
  metadata {
    name = "flux-applier-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux-applier"
    namespace = "flux-system"
  }

  depends_on = [
    azurerm_kubernetes_cluster.this,
    azurerm_kubernetes_flux_configuration.bootstrap
  ]
}   