# ---------------------------------------------------------------------------
# Q13: Nginx TLS Configuration
# ---------------------------------------------------------------------------
# Setup: Deploy nginx with a ConfigMap that only supports TLSv1.2.
#        A self-signed TLS secret (nginx-tls) is also created.
# Task:  Update the ConfigMap to add TLSv1.3 alongside TLSv1.2, then
#        verify both versions work with openssl s_client.

resource "tls_private_key" "nginx_tls" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "nginx_tls" {
  private_key_pem = tls_private_key.nginx_tls.private_key_pem

  subject {
    common_name = "example.com"
  }

  validity_period_hours = 8760 # 365 days

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret_v1" "nginx_tls" {
  metadata {
    name      = "nginx-tls"
    namespace = "default"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.nginx_tls.cert_pem
    "tls.key" = tls_private_key.nginx_tls.private_key_pem
  }
}

# ---------------------------------------------------------------------------
# ConfigMap — nginx.conf intentionally only has TLSv1.2.
# Students must edit this to also include TLSv1.3.
# ---------------------------------------------------------------------------

resource "kubernetes_config_map_v1" "nginx_config" {
  metadata {
    name      = "nginx-config"
    namespace = "default"
  }

  data = {
    "nginx.conf" = <<-NGINX
      events {}
      http {
        server {
          listen 443 ssl;
          server_name example.com;

          ssl_certificate     /etc/nginx/certs/tls.crt;
          ssl_certificate_key /etc/nginx/certs/tls.key;
          ssl_protocols TLSv1.2;

          location / {
            root  /usr/share/nginx/html;
            index index.html;
          }
        }
      }
    NGINX
  }
}

# ---------------------------------------------------------------------------
# nginx Deployment (TLS-terminated, uses ConfigMap + Secret volume mounts)
# ---------------------------------------------------------------------------

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx"

          port {
            container_port = 443
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }

          volume_mount {
            name       = "certs"
            mount_path = "/etc/nginx/certs"
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

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.nginx_config.metadata[0].name
          }
        }

        volume {
          name = "certs"
          secret {
            secret_name = kubernetes_secret_v1.nginx_tls.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_config_map_v1.nginx_config,
    kubernetes_secret_v1.nginx_tls,
  ]
}

# NodePort service so students can reach the nginx pod for TLS testing
resource "kubernetes_service_v1" "nginx_nodeport" {
  metadata {
    name      = "nginx"
    namespace = "default"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 443
      target_port = 443
    }

    type = "NodePort"
  }
}
