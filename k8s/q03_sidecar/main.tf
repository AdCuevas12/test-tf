# ---------------------------------------------------------------------------
# Q3: Sidecar Container
# ---------------------------------------------------------------------------
# Setup: Deploy synergy-leverager — a main container that writes timestamps
#        to /var/log/synergy-leverager.log every second.
# Task:  Add a sidecar container named "sidecar" (busybox:stable) that tails
#        that log file, sharing the /var/log volume.

resource "kubernetes_deployment_v1" "synergy_leverager" {
  metadata {
    name      = "synergy-leverager"
    namespace = "synergy-leverager"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "synergy-leverager"
      }
    }

    template {
      metadata {
        labels = {
          app = "synergy-leverager"
        }
      }

      spec {
        container {
          name  = "app"
          image = "nginx:latest"
          command = [
            "/bin/sh", "-c",
            "while true; do date >> /var/log/synergy-leverager.log; sleep 1; done"
          ]

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

          # NOTE: The /var/log volume mount is NOT pre-configured here.
          # Students must add the emptyDir volume AND mount it on both
          # the main container and the sidecar as part of Q3.
        }

        # The sidecar container block belongs here — students add it.
        # container {
        #   name    = "sidecar"
        #   image   = "busybox:stable"
        #   command = ["/bin/sh", "-c", "tail -n+1 -f /var/log/synergy-leverager.log"]
        #   volume_mount {
        #     name       = "varlog"
        #     mount_path = "/var/log"
        #   }
        # }

        # volumes {
        #   name = "varlog"
        #   empty_dir {}
        # }
      }
    }
  }
}
