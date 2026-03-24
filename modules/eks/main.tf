# ---------------------------------------------------------------------------
# IAM Roles for EKS
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "eks_fargate_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name               = var.eks_cluster_role_name
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "fargate" {
  name               = var.eks_fargate_role_name
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  role       = aws_iam_role.fargate.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# ---------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_sg_id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  enabled_cluster_log_types = []

  tags = {
    Name = var.cluster_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

# ---------------------------------------------------------------------------
# Fargate Profiles
# ---------------------------------------------------------------------------
# Playground allows up to 3 Fargate profiles per cluster.
# We use 3: one for kube-system, one for all CKA question namespaces,
# one reserved for ArgoCD/mgw namespaces that need Helm charts.

locals {
  cka_namespaces = [
    "auto-scale",
    "spline-reticulator",
    "synergy-leverager",
    "priority",
    "mariadb",
    "relative-fawn",
    "sound-repeater",
    "frontend",
    "backend",
    "default",
  ]
}

resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "kube-system"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.fargate_pod_execution,
  ]
}

resource "aws_eks_fargate_profile" "cka_workloads" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "cka-workloads"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = var.subnet_ids

  dynamic "selector" {
    for_each = local.cka_namespaces
    content {
      namespace = selector.value
    }
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.fargate_pod_execution,
  ]
}

resource "aws_eks_fargate_profile" "helm_workloads" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "helm-workloads"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "argocd"
  }

  selector {
    namespace = "mgw-migration"
  }

  selector {
    namespace = "cert-manager"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.fargate_pod_execution,
  ]
}

# ---------------------------------------------------------------------------
# Cluster auth token (used by kubernetes / helm providers in root module)
# ---------------------------------------------------------------------------

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}
