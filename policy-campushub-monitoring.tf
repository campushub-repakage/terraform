# Monitoring Policy
resource "aws_iam_policy" "campushub-monitoring-policy" {
  name = "campushub-monitoring-policy"
  policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"secretsmanager:GetSecretValue",
				"secretsmanager:DescribeSecret"
			],
			"Resource": "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.kubernetes_namespace}/grafana*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:PutObject",  // 청크 업로드
				"s3:GetObject",  // 청크 읽기
				"s3:ListBucket"  // 버킷 안의 오브젝트 찾기
			],
			"Resource": [
				"arn:aws:s3:::${var.kubernetes_namespace}-campus-hub-log",
				"arn:aws:s3:::${var.kubernetes_namespace}-campus-hub-log/*"
			]
		}
	]
})
}
