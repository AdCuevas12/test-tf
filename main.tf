# ---------------------------------------------------------------------------
# VPC & Networking
# ---------------------------------------------------------------------------
# Two public subnets across two AZs, tagged for EKS load balancer discovery.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "EKS self-managed worker node security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}

# ---------------------------------------------------------------------------
# EKS Module
# ---------------------------------------------------------------------------

module "eks" {
  source = "./modules/eks"

  cluster_name          = var.cluster_name
  cluster_version       = var.cluster_version
  eks_cluster_role_name = var.eks_cluster_role_name
  eks_node_role_name    = var.eks_node_role_name
  subnet_ids            = aws_subnet.public[*].id
  cluster_sg_id         = aws_security_group.cluster.id
  node_sg_id            = aws_security_group.nodes.id
  node_instance_type    = var.node_instance_type
  node_desired_count    = var.node_desired_count
  node_min_count        = var.node_min_count
  node_max_count        = var.node_max_count
  node_disk_size        = var.node_disk_size
}

# ---------------------------------------------------------------------------
# Kubernetes Resources (all questions)
# ---------------------------------------------------------------------------
# Deployed after EKS is ready. Grouped by question in the k8s/ subdirectory.

module "k8s_namespaces" {
  source     = "./k8s/namespaces"
  depends_on = [module.eks]
}

module "q01_hpa" {
  source     = "./k8s/q01_hpa"
  depends_on = [module.k8s_namespaces]
}

module "q02_nodeport" {
  source     = "./k8s/q02_nodeport"
  depends_on = [module.k8s_namespaces]
}

module "q03_sidecar" {
  source     = "./k8s/q03_sidecar"
  depends_on = [module.k8s_namespaces]
}

module "q04_priority" {
  source     = "./k8s/q04_priority"
  depends_on = [module.k8s_namespaces]
}


module "q06_argocd" {
  source     = "./k8s/q06_argocd"
  depends_on = [module.k8s_namespaces]
}

module "q07_gateway_migration" {
  source     = "./k8s/q07_gateway_migration"
  depends_on = [module.k8s_namespaces, module.q06_argocd]
}

module "q08_cni" {
  source       = "./k8s/q08_cni"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
  depends_on   = [module.eks]
}

module "q09_wordpress" {
  source     = "./k8s/q09_wordpress"
  depends_on = [module.k8s_namespaces]
}

module "q10_container_runtime" {
  source     = "./k8s/q10_container_runtime"
  depends_on = [module.eks]
}

module "q11_cert_manager" {
  source       = "./k8s/q11_cert_manager"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
  depends_on   = [module.eks]
}

module "q12_netpol" {
  source     = "./k8s/q12_netpol"
  depends_on = [module.k8s_namespaces]
}

module "q13_nginx_tls" {
  source     = "./k8s/q13_nginx_tls"
  depends_on = [module.k8s_namespaces]
}

module "q14_echoserver" {
  source     = "./k8s/q14_echoserver"
  depends_on = [module.k8s_namespaces]
}

module "q15_mariadb" {
  source     = "./k8s/q15_mariadb"
  depends_on = [module.k8s_namespaces]
}
