variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-2"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# Route53 및 도메인 설정
variable "domain_name" {
  description = "Main domain name for the application"
  type        = string
}


# Karpenter 설정
variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "1.0.7"
}

variable "karpenter_log_level" {
  description = "Karpenter log level"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.karpenter_log_level)
    error_message = "Log level must be debug, info, warn, or error."
  }
}

variable "karpenter_capacity_types" {
  description = "Capacity types for Karpenter nodes"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "karpenter_instance_types" {
  description = "Instance types for Karpenter nodes"
  type        = list(string)
  default     = [
    "t3.medium", "t3.large", "t3.xlarge",
    "m5.large", "m5.xlarge", "m5.2xlarge",
    "c5.large", "c5.xlarge", "c5.2xlarge"
  ]
}


variable "karpenter_node_disk_size" {
  description = "Disk size for Karpenter nodes (GB)"
  type        = number
  default     = 20
}

variable "karpenter_max_cpu" {
  description = "Maximum CPU cores for Karpenter nodes"
  type        = number
  default     = 1000
}

variable "karpenter_max_memory" {
  description = "Maximum memory for Karpenter nodes (Gi)"
  type        = number
  default     = 1000
}


variable "enable_karpenter_resources" {
  description = "Enable Karpenter NodeClass and NodePool resources (set to true after EKS cluster is created)"
  type        = bool
  default     = true
}

variable "key_pair_name" {
  description = "사용할 키페어 이름"
  type        = string
  default     = "campushub-key"
}

# 프로젝트 및 리소스 이름 설정
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "campus-hub"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "campushub-cluster"
}

# AWS 계정 설정
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

# S3 버킷 설정
variable "log_bucket_name" {
  description = "Log S3 bucket name"
  type        = string
  default     = "campus-hub-log"
}

# Aurora 설정
variable "aurora_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t3.small"
}

variable "aurora_database_name" {
  description = "Aurora database name"
  type        = string
  default     = "campushub"
}

# Bastion 설정
variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.medium"
}

variable "bastion_ebs_volume_size" {
  description = "Bastion EBS volume size in GB"
  type        = number
  default     = 30
}

# 네임스페이스 설정
variable "kubernetes_namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "campushub"
}

variable "istio_namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "istio-system"
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  type        = string
  default     = "monitoring"
}

# GitHub OIDC 설정
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "Campers-Hub"
}

# 내부 DNS 도메인
variable "internal_domain" {
  description = "Internal DNS domain name"
  type        = string
  default     = "campushub.local"
}

# SA 설정
variable "eso_service_account_name" {
  description = "External Secrets Operator Service Account name"
  type        = string
  default     = "campushub-eso-sa"
}

variable "cert_service_account_name" {
  description = "External Secrets Operator Service Account name"
  type        = string
  default     = "campushub-cert-sa"
}

variable "monitoring_service_account_name" {
  description = "monitoring Service Account name"
  type        = string
  default     = "campushub-monitoring-sa"
}
