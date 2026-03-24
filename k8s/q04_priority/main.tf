# ---------------------------------------------------------------------------
# Q4: PriorityClass
# ---------------------------------------------------------------------------
# Setup: Create the existing-priority class (value 10000000) and the
#        busybox-logger deployment that currently uses no priority class.
# Task:  Create a new PriorityClass named high-priority with value 9999999
#        (one less than existing-priority), then patch busybox-logger to use it.

resource "kubernetes_priority_class_v1" "existing_priority" {
  metadata {
    name = "existing-priority"
  }

  value          = 10000000
  global_default = false
  description    = "Existing user priority class"
}

resource "kubernetes_deployment_v1" "busybox_logger" {
  metadata {
    name      = "busybox-logger"
    namespace = "priority"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "busybox-logger"
      }
    }

    template {
      metadata {
        labels = {
          app = "busybox-logger"
        }
      }

      spec {
        # priority_class_name is intentionally absent — students set it in Q4.

        container {
          name    = "busybox"
          image   = "busybox"
          command = ["sh", "-c", "while true; do echo 'Logging...'; sleep 5; done"]

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

  depends_on = [kubernetes_priority_class_v1.existing_priority]
}
