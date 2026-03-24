# ---------------------------------------------------------------------------
# Q7: Gateway API Migration
# ---------------------------------------------------------------------------
# Setup: Deploy the existing Ingress-based web application in mgw-migration.
#        Includes: nginx ingress controller (Helm), self-signed TLS secret,
#        the Ingress resource, web-app deployment, and web-service.
# Task:  Students migrate the Ingress to a Gateway API Gateway + HTTPRoute.

# ---------------------------------------------------------------------------
# NGINX Ingress Controller for mgw-migration
# ---------------------------------------------------------------------------

resource "helm_release" "ingress_nginx_mgw" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "mgw-migration"
  create_namespace = false

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  timeout = 600
  wait    = true
}

# ---------------------------------------------------------------------------
# NGINX Gateway Fabric (Gateway API implementation)
# OCI charts cannot use the repository field — use the full chart reference.
# ---------------------------------------------------------------------------

resource "helm_release" "nginx_gateway_fabric" {
  name             = "nginx-gateway"
  repository       = "oci://ghcr.io/nginxinc/charts"
  chart            = "nginx-gateway-fabric"
  namespace        = "mgw-migration"
  create_namespace = false

  set {
    name  = "gatewayClass.name"
    value = "nginx-gateway-class"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  timeout = 600
  wait    = false

  depends_on = [helm_release.ingress_nginx_mgw]
}

# ---------------------------------------------------------------------------
# Self-signed TLS certificate for web-tls secret
# ---------------------------------------------------------------------------

resource "tls_private_key" "web_tls" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "web_tls" {
  private_key_pem = tls_private_key.web_tls.private_key_pem

  subject {
    common_name = "ingress.web.k8s.local"
  }

  validity_period_hours = 8760 # 365 days

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret_v1" "web_tls" {
  metadata {
    name      = "web-tls"
    namespace = "mgw-migration"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.web_tls.cert_pem
    "tls.key" = tls_private_key.web_tls.private_key_pem
  }

  depends_on = [helm_release.ingress_nginx_mgw]
}

# ---------------------------------------------------------------------------
# web-app Deployment
# ---------------------------------------------------------------------------

resource "kubernetes_deployment_v1" "web_app" {
  metadata {
    name      = "web-app"
    namespace = "mgw-migration"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "web-app"
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
# web-service (ClusterIP)
# ---------------------------------------------------------------------------

resource "kubernetes_service_v1" "web_service" {
  metadata {
    name      = "web-service"
    namespace = "mgw-migration"
  }

  spec {
    selector = {
      app = "web-app"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# ---------------------------------------------------------------------------
# Ingress resource (what students will migrate FROM in Q7)
# ---------------------------------------------------------------------------

resource "kubernetes_ingress_v1" "web" {
  metadata {
    name      = "web"
    namespace = "mgw-migration"

    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target"      = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"        = "true"
      "nginx.ingress.kubernetes.io/use-http2"           = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size"     = "8m"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "30s"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"  = "30s"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["ingress.web.k8s.local"]
      secret_name = "web-tls"
    }

    rule {
      host = "ingress.web.k8s.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "web-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.ingress_nginx_mgw,
    kubernetes_secret_v1.web_tls,
    kubernetes_service_v1.web_service,
  ]
}
