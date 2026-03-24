# ---------------------------------------------------------------------------
# Q6: ArgoCD Installation (Helm)
# ---------------------------------------------------------------------------
# Setup: Deploy ArgoCD CRDs into the cluster so they are pre-installed.
# Task:  Students must:
#        1. Add the official argo helm repo (name: argo)
#        2. Run: helm template argocd argo/argo-cd --version 7.7.3
#                  -n argocd --skip-crds > ~/argo-helm.yaml
#        3. The generated template must have CRD installation disabled.
#
# The ArgoCD CRDs are pre-applied so students can practice the template step.

resource "helm_release" "argocd_crds" {
  name             = "argocd-crds"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.3"
  namespace        = "argocd"
  create_namespace = false

  set {
    name  = "crds.install"
    value = "true"
  }

  set {
    name  = "crds.keep"
    value = "true"
  }

  # Disable all application components — CRDs only
  set {
    name  = "server.enabled"
    value = "false"
  }

  set {
    name  = "controller.enabled"
    value = "false"
  }

  set {
    name  = "repoServer.enabled"
    value = "false"
  }

  set {
    name  = "applicationSet.enabled"
    value = "false"
  }

  set {
    name  = "notifications.enabled"
    value = "false"
  }

  set {
    name  = "dex.enabled"
    value = "false"
  }

  set {
    name  = "redis.enabled"
    value = "false"
  }

  wait    = false
  timeout = 300
}
