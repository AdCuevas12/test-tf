# ---------------------------------------------------------------------------
# Q2: NodePort Service
# ---------------------------------------------------------------------------
# Setup: Deploy front-end (nginx) in the spline-reticulator namespace
#        WITHOUT a containerPort defined — that is part of the task.
# Task:  Reconfigure the deployment to expose port 80/tcp, then create
#        a NodePort service named front-end-svc.

resource "kubernetes_deployment_v1" "front_end" {
  metadata {
    name      = "front-end"
    namespace = "spline-reticulator"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "front-end"
      }
    }

    template {
      metadata {
        labels = {
          app = "front-end"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"

          # No containerPort here intentionally — students add port 80/tcp
          # and create the NodePort service as part of Q2.

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
