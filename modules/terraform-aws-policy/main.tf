resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.value.name
  description = try(each.value.description, null)
  path        = try(each.value.path, null)
  policy      = each.value.policy_json
  tags        = try(each.value.tags, null)
}