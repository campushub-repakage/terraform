# Campus Hub Git Actions Policy
resource "aws_iam_policy" "campus-hub-git-actions-policy" {
  name = "campus-hub-git-actions-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "GetAuthorizationToken"
        Effect = "Allow"
        Action = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid = "Statement1"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:PutImageTagMutability"
        ]
        Resource = [
          "arn:aws:ecr:ap-northeast-2:569934397842:repository/campushub",
          "arn:aws:ecr:ap-northeast-2:569934397842:repository/campushub/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:role/${var.kubernetes_namespace}-*"
      }
    ]
  })
}
