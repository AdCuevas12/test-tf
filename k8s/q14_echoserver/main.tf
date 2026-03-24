# ---------------------------------------------------------------------------
# Q14: Ingress for echoserver
# ---------------------------------------------------------------------------
# Setup: Deploy echoserver (nginx) and echoserver-service (port 8080→80)
#        in the sound-repeater namespace. Install a second NGINX Ingress
#        Controller with ingressClass: sound-repeater-nginx.
# Task:  Create an Ingress that routes http://echo.local/echo to
#        echoserver-service:8080 using sound-repeater-nginx.

# ---------------------------------------------------------------------------
# NGINX Ingress Controller — sound-repeater-nginx class (NodePort)
# ---------------------------------------------------------------------------

resource "helm_release" "ingress_nginx_sound_repeater" {
  name             = "sound-repeater-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "sound-repeater"
  create_namespace = false

  set {
    name  = "controller.ingressClass"
    value = "sound-repeater-nginx"
  }

  set {
    name  = "controller.ingressClassResource.name"
    value = "sound-repeater-nginx"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = "true"
    type  = "auto"
  }

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  timeout = 600
  wait    = true
}

# ---------------------------------------------------------------------------
# echoserver Deployment
# ---------------------------------------------------------------------------

resource "kubernetes_deployment_v1" "echoserver" {
  metadata {
    name      = "echoserver"
    namespace = "sound-repeater"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "echoserver"
      }
    }

    template {
      metadata {
        labels = {
          app = "echoserver"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"

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
# echoserver-service (ClusterIP, port 8080 → container 80)
# ---------------------------------------------------------------------------

resource "kubernetes_service_v1" "echoserver_service" {
  metadata {
    name      = "echoserver-service"
    namespace = "sound-repeater"
  }

  spec {
    selector = {
      app = "echoserver"
    }

    port {
      protocol    = "TCP"
      port        = 8080
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# ---------------------------------------------------------------------------
# NOTE — The Ingress resource is the ANSWER to Question 14.
# Students create it manually. Reference (do not apply):
#
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: echoserver-ingress
#   namespace: sound-repeater
# spec:
#   ingressClassName: sound-repeater-nginx
#   rules:
#     - host: echo.local
#       http:
#         paths:
#           - path: /echo
#             pathType: Prefix
#             backend:
#               service:
#                 name: echoserver-service
#                 port:
#                   number: 8080
# ---------------------------------------------------------------------------
