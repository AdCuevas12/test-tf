variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "cka-mock-exam"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_cluster_role_name" {
  description = "IAM role name for the EKS cluster"
  type        = string
  default     = "eksClusterRole"
}

variable "eks_fargate_role_name" {
  description = "IAM role name for Fargate pod execution"
  type        = string
  default     = "AmazonEKSFargatePodExecutionRole"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
