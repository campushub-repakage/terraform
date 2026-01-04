variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    name        = string
    description = optional(string)
    path        = optional(string)
    tags        = optional(map(string))
    policy_json = any
  }))
}
