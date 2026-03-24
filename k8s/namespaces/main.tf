# All namespaces required by the CKA mock exam questions.

locals {
  namespaces = [
    "auto-scale",         # Q1  - HPA
    "spline-reticulator", # Q2  - NodePort
    "synergy-leverager",  # Q3  - Sidecar
    "priority",           # Q4  - PriorityClass
    "mariadb",            # Q6 / Q15 - PV + MariaDB restore
    "mgw-migration",      # Q7  - Gateway API migration
    "relative-fawn",      # Q9  - WordPress resource allocation
    "sound-repeater",     # Q14 - Ingress / echoserver
    "frontend",           # Q12 - NetworkPolicy
    "backend",            # Q12 - NetworkPolicy
    "argocd",             # Q6  - ArgoCD installation
  ]
}

resource "kubernetes_namespace" "this" {
  for_each = toset(local.namespaces)

  metadata {
    name = each.value
  }
}
