# ---------------------------------------------------------------------------
# Q9: WordPress Resource Allocation
# ---------------------------------------------------------------------------
# Setup: Deploy WordPress with 3 replicas and an init container, but with
#        resource requests that cause scheduling failures (too high).
# Task:  Students must scale down to 0, fix resource requests so 3 pods
#        can be evenly distributed across nodes, then scale back to 3.
#
# Playground node: t3.medium = 2 vCPU / 4 GiB per node, 2 nodes.
# Rough fair share per pod across 3 pods on 2 nodes:
#   CPU:    ~600m  (~1200m allocatable / 2 nodes / 3 pods)
#   Memory: ~512Mi
# The setup intentionally sets requests too high to trigger the failure.

resource "kubernetes_deployment_v1" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = "relative-fawn"
  }

  spec {
    # 3 replicas — pods will fail to schedule with the inflated requests below
    replicas = 3

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        # Init container — students must apply the same resource fix here too
        init_container {
          name    = "init-wordpress"
          image   = "busybox"
          command = ["sh", "-c", "echo Initializing && sleep 5"]

          resources {
            # Intentionally over-provisioned to simulate the exam scenario
            requests = {
              cpu    = "600m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "800m"
              memory = "768Mi"
            }
          }
        }

        container {
          name  = "wordpress"
          image = "wordpress:latest"

          port {
            container_port = 80
          }

          resources {
            # Intentionally over-provisioned — students must fix these
            requests = {
              cpu    = "600m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "800m"
              memory = "768Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "wordpress_svc" {
  metadata {
    name      = "wordpress-svc"
    namespace = "relative-fawn"
  }

  spec {
    selector = {
      app = "wordpress"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}
