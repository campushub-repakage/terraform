# Campushub ESO Policy
resource "aws_iam_policy" "campushub-eso-policy" {
  name = "campushub-eso-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.kubernetes_namespace}/*",
          "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.istio_namespace}/*",        
          ]

      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService": "secretsmanager.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}
