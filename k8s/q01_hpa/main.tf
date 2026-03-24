# ---------------------------------------------------------------------------
# Q1: Horizontal Pod Autoscaler (HPA)
# ---------------------------------------------------------------------------
# Setup: Deploy apache-server in the auto-scale namespace.
# Task:  Create an HPA named apache-server targeting that deployment,
#        CPU target 50%, min 1 / max 4 replicas, downscale stabilization 30s.

resource "kubernetes_deployment_v1" "apache_server" {
  metadata {
    name      = "apache-server"
    namespace = "auto-scale"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "apache-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "apache-server"
        }
      }

      spec {
        container {
          name  = "apache"
          image = "httpd:2.4"

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
# NOTE — The HPA itself is the ANSWER to Question 1.
# Students must create it manually to practice the exam skill.
# The resource below is commented out to preserve the exercise.
#
# resource "kubernetes_horizontal_pod_autoscaler_v2" "apache_server" {
#   metadata {
#     name      = "apache-server"
#     namespace = "auto-scale"
#   }
#
#   spec {
#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = "apache-server"
#     }
#     min_replicas = 1
#     max_replicas = 4
#
#     metric {
#       type = "Resource"
#       resource {
#         name = "cpu"
#         target {
#           type                = "Utilization"
#           average_utilization = 50
#         }
#       }
#     }
#
#     behavior {
#       scale_down {
#         stabilization_window_seconds = 30
#       }
#     }
#   }
# }
