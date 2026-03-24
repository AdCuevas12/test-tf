variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "eks_cluster_role_name" {
  type = string
}

variable "eks_node_role_name" {
  type    = string
  default = "AmazonEKSNodeRole"
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_sg_id" {
  type = string
}

variable "node_sg_id" {
  type = string
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_desired_count" {
  type    = number
  default = 2
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
  type    = number
  default = 20
}
