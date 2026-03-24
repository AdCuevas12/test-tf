# ---------------------------------------------------------------------------
# Q8: Calico CNI Installation
# ---------------------------------------------------------------------------
# Setup: Install the Tigera Operator (Calico v3.28.2) so students can
#        observe the CNI and practice the installation steps.
# Task:  Students must apply the Tigera operator manifest and verify Calico
#        is running.
#
# NOTE: On EKS, the default VPC CNI is aws-node. Calico can be installed
#       on top for NetworkPolicy enforcement (policy-only mode).
#       The Tigera operator is applied via a null_resource using kubectl
#       because the CRDs it ships cannot be expressed as standard k8s
#       Terraform resources before they exist.

resource "null_resource" "calico_tigera_operator" {
  triggers = {
    calico_version = "v3.28.2"
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name} --kubeconfig /tmp/kubeconfig-cka
      kubectl --kubeconfig /tmp/kubeconfig-cka apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
    EOT
  }
}
