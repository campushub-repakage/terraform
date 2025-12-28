variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.31"
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for the cluster"
}

