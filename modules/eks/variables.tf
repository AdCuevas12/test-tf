variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "eks_cluster_role_name" {
  type = string
}

variable "eks_fargate_role_name" {
  type    = string
  default = "AmazonEKSFargatePodExecutionRole"
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_sg_id" {
  type = string
}
