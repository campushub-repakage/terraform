variable "create_role" {
  description = "Whether to create the IAM role"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "assume_role_policy" {
  description = "Assume role policy document"
  type        = string
}


variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

