# ---------------------------------------------------------------------------
# Q11: cert-manager CRDs
# ---------------------------------------------------------------------------
# Setup: Apply cert-manager CRDs v1.17.2 so students can:
#        1. List all cert-manager CRDs → ~/custom-crd.txt
#        2. Extract the "subject" field from the certificates CRD
#           → ~/cert-manager-subject.txt
#
# CRDs are applied via null_resource because the custom resource definitions
# themselves cannot be managed by the Terraform kubernetes provider until
# after they exist.

resource "null_resource" "cert_manager_crds" {
  triggers = {
    cert_manager_version = "v1.17.2"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.crds.yaml"
  }
}
