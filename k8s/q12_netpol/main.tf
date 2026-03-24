# ---------------------------------------------------------------------------
# Q12: NetworkPolicy (choose the least permissive)
# ---------------------------------------------------------------------------
# Setup: Deploy frontend (ns: frontend) and backend (ns: backend), then
#        create three NetworkPolicy files for students to evaluate.
# Task:  Apply the LEAST permissive policy that still allows frontend pods
#        to reach backend pods on port 8080.
#        Answer: Policy 2 (namespaceSelector + podSelector, no open CIDR).

# ---------------------------------------------------------------------------
# frontend Deployment
# ---------------------------------------------------------------------------

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = "frontend"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# backend Deployment
# ---------------------------------------------------------------------------

resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = "backend"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# NetworkPolicy Option 1 — MOST permissive (open ingress, all pods, all sources)
# Students should NOT choose this one.
# ---------------------------------------------------------------------------

resource "kubernetes_network_policy_v1" "frontend_to_backend_1" {
  metadata {
    name      = "frontend-to-backend-1"
    namespace = "backend"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]

    ingress {
      # Empty from block = allow all sources
      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# NetworkPolicy Option 2 — LEAST permissive (namespaceSelector + podSelector)
# This is the correct answer for Q12.
# ---------------------------------------------------------------------------

resource "kubernetes_network_policy_v1" "frontend_to_backend_2" {
  metadata {
    name      = "frontend-to-backend-2"
    namespace = "backend"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "backend"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "frontend"
          }
        }
        pod_selector {
          match_labels = {
            app = "frontend"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# NetworkPolicy Option 3 — MORE permissive than option 2 (adds CIDR block)
# Students should NOT choose this one over option 2.
# ---------------------------------------------------------------------------

resource "kubernetes_network_policy_v1" "frontend_to_backend_3" {
  metadata {
    name      = "frontend-to-backend-3"
    namespace = "backend"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "backend"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "frontend"
          }
        }
        pod_selector {
          match_labels = {
            app = "frontend"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }

    # Extra CIDR rule makes this MORE permissive than option 2
    ingress {
      from {
        ip_block {
          cidr = "192.168.1.0/24"
        }
      }

      ports {
        protocol = "TCP"
        port     = "8080"
      }
    }
  }
}
