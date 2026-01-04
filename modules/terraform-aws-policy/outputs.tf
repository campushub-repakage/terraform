output "arns" {
  description = "Policy ARNs keyed by policies map key"
  value       = { for k, v in aws_iam_policy.this : k => v.arn }
}

output "names" {
  description = "Policy names keyed by policies map key"
  value       = { for k, v in aws_iam_policy.this : k => v.name }
}
