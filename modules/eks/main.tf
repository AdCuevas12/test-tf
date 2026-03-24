# ---------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------
# Uses the playground's pre-created IAM roles (eksClusterRole / AmazonEKSNodeRole).

data "aws_iam_role" "cluster" {
  name = var.eks_cluster_role_name
}

data "aws_iam_role" "node" {
  name = var.eks_node_role_name
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = data.aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.cluster_sg_id]
    # Public endpoint so kubectl works from the playground terminal
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Allow EKS to manage cluster log group retention
  enabled_cluster_log_types = []

  tags = {
    Name = var.cluster_name
  }
}

# ---------------------------------------------------------------------------
# EKS Managed Node Group
# ---------------------------------------------------------------------------
# t3.medium = 2 vCPU / 4 GiB — exactly the playground per-instance ceiling.
# Two nodes = total 4 vCPU / 8 GiB, within the 10 vCPU / 20 GiB account cap.

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = data.aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  disk_size = var.node_disk_size   # GP2 by default; max 30 GB per playground

  # Amazon Linux 2 — supported OS per playground
  ami_type = "AL2_x86_64"

  tags = {
    Name = "${var.cluster_name}-node-group"
  }

  depends_on = [aws_eks_cluster.this]
}

# ---------------------------------------------------------------------------
# Cluster auth token (used by kubernetes / helm providers in root module)
# ---------------------------------------------------------------------------

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}
