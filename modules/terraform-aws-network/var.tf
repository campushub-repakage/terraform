variable "nat_eip_id" {
  description = "NAT Gateway용 EIP의 ID"
  type        = string
}

variable "name_prefix" {
  description = "이름에 사용할 prefix"
  type        = string
}

variable "vpc_id" { 
  type = string 
}

variable "public_subnet_ids" {
   type = string 
}

variable "private_subnet_ids" {
   type = string
}