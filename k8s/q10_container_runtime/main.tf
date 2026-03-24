# ---------------------------------------------------------------------------
# Q10: cri-dockerd + sysctl (Node-level configuration)
# ---------------------------------------------------------------------------
# This question tests system administration on a bare Linux host — not a
# Kubernetes or AWS resource.  The tasks are:
#
#   1. Install the cri-dockerd Debian package
#      (~/cri-dockerd_0.3.9.3-0.ubuntu-focal_amd64.deb)
#   2. Start & enable the cri-dockerd systemd service
#   3. Set sysctl params:
#      - net.bridge.bridge-nf-call-iptables = 1
#      - net.ipv6.conf.all.forwarding       = 1
#      - net.ipv4.ip_forward               = 1
#
# Setup: The cri-dockerd .deb package is downloaded as part of env-setup
#        and placed at ~/cri-dockerd_0.3.9.3-0.ubuntu-focal_amd64.deb
#        on each worker node.
#
# The null_resource below downloads the package onto each node via an
# EKS DaemonSet that runs the download + sysctl commands as a privileged
# init job.  This mirrors the original env-setup.sh behaviour.

resource "kubernetes_daemon_set_v1" "q10_setup" {
  metadata {
    name      = "q10-node-setup"
    namespace = "kube-system"

    labels = {
      app = "q10-node-setup"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "q10-node-setup"
      }
    }

    template {
      metadata {
        labels = {
          app = "q10-node-setup"
        }
      }

      spec {
        # Run on every node, including control-plane (EKS managed)
        toleration {
          operator = "Exists"
        }

        host_pid     = true
        host_network = true

        init_container {
          name  = "download-cri-dockerd"
          image = "amazonlinux:2"

          # Download cri-dockerd package to the node's /tmp and set sysctl
          command = [
            "/bin/bash", "-c",
            <<-EOT
              set -e
              curl -L -o /host-tmp/cri-dockerd_0.3.9.3-0.ubuntu-focal_amd64.deb \
                https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/cri-dockerd_0.3.9.3-0.ubuntu-focal_amd64.deb
              # Set sysctl via host /proc filesystem
              echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables || true
              echo 1 > /proc/sys/net/ipv6/conf/all/forwarding        || true
              echo 1 > /proc/sys/net/ipv4/ip_forward                 || true
            EOT
          ]

          volume_mount {
            name       = "host-tmp"
            mount_path = "/host-tmp"
          }

          volume_mount {
            name       = "proc"
            mount_path = "/proc"
          }

          security_context {
            privileged = true
          }
        }

        # Long-running pause container — keeps the DaemonSet pod alive
        container {
          name  = "pause"
          image = "gcr.io/google_containers/pause:3.9"

          resources {
            requests = {
              cpu    = "10m"
              memory = "16Mi"
            }
            limits = {
              cpu    = "10m"
              memory = "16Mi"
            }
          }
        }

        volume {
          name = "host-tmp"
          host_path {
            path = "/tmp"
          }
        }

        volume {
          name = "proc"
          host_path {
            path = "/proc"
          }
        }
      }
    }
  }
}
