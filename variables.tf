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

variable "eks_node_role_name" {
  description = "IAM role name for self-managed worker nodes"
  type        = string
  default     = "AmazonEKSNodeRole"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes (max 2 vCPU / 4 GiB per playground limits)"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  description = "EBS volume size in GB per node (max 30 per playground limits)"
  type        = number
  default     = 20
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
