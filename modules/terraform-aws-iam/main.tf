# IAM Role
resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0
  
  name = var.role_name

  assume_role_policy = var.assume_role_policy
}


# IAM Role Policy Attachment (Managed Policies)
resource "aws_iam_role_policy_attachment" "managed_policies" {
  count = var.create_role ? length(var.managed_policy_arns) : 0

  role       = aws_iam_role.this[0].name
  policy_arn = var.managed_policy_arns[count.index]
}