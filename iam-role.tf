# EKS Cluster Role
module "eks_cluster_role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}

# campus-hub-git-role
module "campus-hub-git-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campus-hub-git-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
				"StringEquals": {
					"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
				},
				"StringLike": {
					"token.actions.githubusercontent.com:sub": "repo:${var.github_org}/*"
				}
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campus-hub-git-actions-policy.arn
  ]
}

# campushub-eso-role
module "campushub-eso-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-eso-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": module.eks-cluster.oidc_provider_arn
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
            "StringEquals": {
              "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub": [
                "system:serviceaccount:${var.kubernetes_namespace}:${var.eso_service_account_name}",
                "system:serviceaccount:${var.istio_namespace}:${var.cert_service_account_name}"
              ],
              "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"
            }
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-eso-policy.arn
  ]
}

# campushub-IRSA-class-role
module "campushub-IRSA-class-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-IRSA-class-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": module.eks-cluster.oidc_provider_arn
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
            "StringEquals": {
              "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub": [
                "system:serviceaccount:${var.kubernetes_namespace}:${var.eso_service_account_name}",
                "system:serviceaccount:${var.kubernetes_namespace}:class-sa"
              ],
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"

            }
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-class-role.arn
  ]
}

# campushub-IRSA-user-auth-role
module "campushub-IRSA-user-auth-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-IRSA-user-auth-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": module.eks-cluster.oidc_provider_arn
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
            "StringEquals": {
              "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub": [
                "system:serviceaccount:${var.kubernetes_namespace}:${var.eso_service_account_name}",
                "system:serviceaccount:${var.kubernetes_namespace}:user-sa",
                "system:serviceaccount:${var.kubernetes_namespace}:auth-sa"
              ],
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"

            }
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-IRSA-user-auth-policy.arn
  ]
}

# campushub-monitoring-role
module "campushub-monitoring-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-monitoring-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": module.eks-cluster.oidc_provider_arn
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
				"StringEquals": {
					"${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:${var.monitoring_namespace}:${var.monitoring_service_account_name}",
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"

				}
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-monitoring-policy.arn
  ]
}

# campushub-IRSA-lbc-role
module "campushub-IRSA-lbc-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-IRSA-lbc-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": module.eks-cluster.oidc_provider_arn
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
            "StringEquals": {
              "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
                    "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"
            }
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-IRSA-lbc-policy.arn
  ]
}

# campushub-karpenterController-role
module "campushub-karpenterController-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-karpenterController-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": module.eks-cluster.oidc_provider_arn
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
            "StringEquals": {
              "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:kube-system:karpenter",
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"

            }
			}
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-karpenterController-policy.arn
  ]
}

# campushub-karpenterNode-role
module "campushub-karpenterNode-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-karpenterNode-role"
  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "ec2.amazonaws.com"
			},
			"Action": "sts:AssumeRole"
		}
	]
  })
  managed_policy_arns = [
    aws_iam_policy.campushub-karpenterNode-policy.arn,
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

# External DNS Role
module "external_dns_role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-external-dns-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = module.eks-cluster.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns",
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  managed_policy_arns = [
    aws_iam_policy.external_dns_policy.arn
  ]
}

# EBS CSI Driver Role
module "campushub-IRSA-ebs-csi-role" {
  source = "./modules/terraform-aws-role"
  role_name = "campushub-IRSA-ebs-csi-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = module.eks-cluster.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa",
          "${replace(module.eks-cluster.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}

# Lambda 함수용 IAM 역할
resource "aws_iam_role" "campushub_lambda_role" {
  name = "campushub-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda 기본 실행 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.campushub_lambda_role.name
}

# Lambda 커스텀 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_custom_policy" {
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
  role       = aws_iam_role.campushub_lambda_role.name
}

# Lambda VPC 실행 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.campushub_lambda_role.name
}
