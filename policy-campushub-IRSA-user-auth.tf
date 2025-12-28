# User Auth Policy
resource "aws_iam_policy" "campushub-IRSA-user-auth-policy" {
  name = "campushub-IRSA-user-auth-policy"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSpecificSecrets",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:campushub/*"
    },
    {
      "Sid": "DefenseInDepthDenyWrites",
      "Effect": "Deny",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:RotateSecret",
        "secretsmanager:RestoreSecret",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSFullCRUD",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBInstance",
        "rds:ModifyDBInstance",
        "rds:DeleteDBInstance",
        "rds:CreateDBCluster",
        "rds:ModifyDBCluster",
        "rds:DeleteDBCluster",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "rds:DescribeDBProxies"
      ],
      "Resource": "*"
    }
  ]
  })
}
