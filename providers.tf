provider "aws" {
  region = var.aws_region
}

# Kubernetes and Helm providers are configured after EKS cluster is ready.
# They reference the cluster endpoint and auth token from the aws_eks_cluster data source.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = module.eks.cluster_token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = module.eks.cluster_token
  }
}
