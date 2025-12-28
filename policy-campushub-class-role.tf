# Class Role Policy
resource "aws_iam_policy" "campushub-class-role" {
  name = "campushub-class-role"
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
      "Resource": "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.kubernetes_namespace}/*"
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
      "Sid": "S3MultipartCoreRW",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::campus-hub-bucket/materials/*",
        "arn:aws:s3:::campus-hub-bucket/tasks/*"
      ]
    },
    {
      "Sid": "S3ListBucketForPrefixes",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::campus-hub-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "materials/*",
            "tasks/*"
          ]
        }
      }
    },
    {
      "Sid": "DDBRWStudentAttendanceOnly",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:Query",
        "dynamodb:DescribeTable",
        "dynamodb:Scan"
      ],
      "Resource": [
        "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/StudentAttendance",
        "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/StudentAttendance/index/*"
      ]
    }
  ]
})
}
