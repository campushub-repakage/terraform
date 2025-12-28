variable "name_prefix" {
  description = "이름에 사용할 prefix"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs (used for subnet grouping by index)"
  type        = list(string)
}

variable "public_subnet_config" {
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "private_subnet_config" {
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

