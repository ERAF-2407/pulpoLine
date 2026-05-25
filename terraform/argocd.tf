resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.11" # A stable version for ArgoCD Helm Chart
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Configuramos ArgoCD Server para ser accesible vía NodePort o ClusterIP
  # (por defecto es ClusterIP, lo podemos exponer mediante NodePort o Port Forward para pruebas iniciales)
  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  # Deshabilitamos configs extra por ahora para un setup de lab limpio
  set {
    name  = "configs.params.server.insecure"
    value = "true" # Util si se quiere usar un proxy inverso en vez de TLS nativo
  }
}
