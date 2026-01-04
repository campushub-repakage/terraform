module "campushub_policies" {
  source = "./modules/terraform-aws-policy"

  policies = {

    # campushub-class-policy
    class_policy = {
      name = "campushub-class-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "ReadSpecificSecrets"
            Effect = "Allow"
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ]
            Resource = "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.kubernetes_namespace}/*"
          },
          {
            Sid    = "DefenseInDepthDenyWrites"
            Effect = "Deny"
            Action = [
              "secretsmanager:CreateSecret",
              "secretsmanager:PutSecretValue",
              "secretsmanager:UpdateSecret",
              "secretsmanager:DeleteSecret",
              "secretsmanager:RotateSecret",
              "secretsmanager:RestoreSecret",
              "secretsmanager:TagResource",
              "secretsmanager:UntagResource"
            ]
            Resource = "*"
          },
          {
            Sid    = "S3MultipartCoreRW"
            Effect = "Allow"
            Action = [
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject",
              "s3:AbortMultipartUpload"
            ]
            Resource = [
              "arn:aws:s3:::campus-hub-bucket/materials/*",
              "arn:aws:s3:::campus-hub-bucket/tasks/*"
            ]
          },
          {
            Sid    = "S3ListBucketForPrefixes"
            Effect = "Allow"
            Action = [
              "s3:ListBucket",
              "s3:ListBucketMultipartUploads"
            ]
            Resource = "arn:aws:s3:::campus-hub-bucket"
            Condition = {
              StringLike = {
                "s3:prefix" = [
                  "materials/*",
                  "tasks/*"
                ]
              }
            }
          },
          {
            Sid    = "DDBRWStudentAttendanceOnly"
            Effect = "Allow"
            Action = [
              "dynamodb:GetItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem",
              "dynamodb:DeleteItem",
              "dynamodb:BatchGetItem",
              "dynamodb:BatchWriteItem",
              "dynamodb:Query",
              "dynamodb:DescribeTable",
              "dynamodb:Scan"
            ]
            Resource = [
              "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/StudentAttendance",
              "arn:aws:dynamodb:${var.region}:${var.aws_account_id}:table/StudentAttendance/index/*"
            ]
          }
        ]
      }
    }

    # campushub-eso-policy
    eso_policy = {
      name = "campushub-eso-policy"
      policy_json = {
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
              "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.istio_namespace}/*"
            ]
          },
          {
            Effect   = "Allow"
            Action   = ["kms:Decrypt"]
            Resource = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/*"
            Condition = {
              StringEquals = {
                "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
              }
            }
          }
        ]
      }
    }

    # campushub-external-dns-policy
    external_dns_policy = {
      name = "campushub-external-dns-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
            "route53:ChangeResourceRecordSets"
            ]
            Resource = [
            "arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"
            ]
        },
        {
            Effect = "Allow"
            Action = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
            ]
            Resource = "*"
        }
        ]
    }
    }

    # campushub-IRSA-lbc-policy
    irsa_lbc_policy = {
      name = "campushub-irsa-lbc-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement = [
        {
        "Sid": "ElasticLoadBalancingFullAccess",
        "Effect": "Allow",
        "Action": [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerAttributes",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:RemoveTags",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:SetWebAcl"
        ],
        "Resource": "*"
        },
        {
        Sid = "AllowEC2ForLB",
        Effect = "Allow",
        Action = [
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup",
            "ec2:Describe*"
        ],
        Resource = "*"
        },
        {
        "Sid": "EC2ReadOnlyForLB",
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeTags",
            "ec2:GetCoipPoolUsage",
            "ec2:DescribeCoipPools",
            "ec2:CreateSecurityGroup"
        ],
        "Resource": "*"
        },
        {
        "Sid": "IAMForLB",
        "Effect": "Allow",
        "Action": [
            "iam:CreateServiceLinkedRole",
            "iam:GetServerCertificate",
            "iam:ListServerCertificates"
        ],
        "Resource": "*"
        },
        {
        "Sid": "TaggingForLB",
        "Effect": "Allow",
        "Action": [
            "tag:GetResources",
            "tag:TagResources",
            "tag:UntagResources"
        ],
        "Resource": "*"
        },
        {
        "Sid": "WAFandACMForLB",
        "Effect": "Allow",
        "Action": [
            "waf-regional:GetWebACLForResource",
            "waf-regional:GetWebACL",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:GetWebACL",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "shield:DescribeProtection",
            "shield:GetSubscriptionState",
            "shield:DeleteProtection",
            "shield:CreateProtection",
            "shield:DescribeSubscription",
            "shield:ListProtections",
            "acm:ListCertificates",
            "acm:DescribeCertificate"
        ],
        "Resource": "*"
        }
    ]
    }

    # campushub-IRSA-user-auth-policy
    user_auth_policy = {
      name = "campushub-user-auth-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement: [
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
        }
    }

    # campushub-karpenter-policy
    karpenter_policy = {
      name = "campushub-karpenter-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement : [
        {
            "Effect" : "Allow",
            "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchImportUpstreamImage"
            ],
            "Resource" : "*"
        },
        {
            "Sid" : "AmazonEKSCNIPolicy",
            "Effect" : "Allow",
            "Action" : [
            "ec2:AssignPrivateIpAddresses",
            "ec2:AttachNetworkInterface",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:DescribeTags",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeSubnets",
            "ec2:DetachNetworkInterface",
            "ec2:ModifyNetworkInterfaceAttribute",
            "ec2:UnassignPrivateIpAddresses"
            ],
            "Resource" : "*"
        },
        {
            "Sid" : "AmazonEKSCNIPolicyENITag",
            "Effect" : "Allow",
            "Action" : [
            "ec2:CreateTags"
            ],
            "Resource" : [
            "arn:aws:ec2:*:*:network-interface/*"
            ]
        },
        {
            "Sid" : "WorkerNodePermissions",
            "Effect" : "Allow",
            "Action" : [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumesModifications",
            "ec2:DescribeVpcs",
            "eks:DescribeCluster",
            "eks-auth:AssumeRoleForPodIdentity"
            ],
            "Resource" : "*"
        },
        {
            "Effect" : "Allow",
            "Action" : [
            "ssm:DescribeAssociation",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetDocument",
            "ssm:DescribeDocument",
            "ssm:GetManifest",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssm:PutInventory",
            "ssm:PutComplianceItems",
            "ssm:PutConfigurePackageResult",
            "ssm:UpdateAssociationStatus",
            "ssm:UpdateInstanceAssociationStatus",
            "ssm:UpdateInstanceInformation"
            ],
            "Resource" : "*"
        },
        {
            "Effect" : "Allow",
            "Action" : [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
            ],
            "Resource" : "*"
        },
        {
            "Effect" : "Allow",
            "Action" : [
            "ec2messages:AcknowledgeMessage",
            "ec2messages:DeleteMessage",
            "ec2messages:FailMessage",
            "ec2messages:GetEndpoint",
            "ec2messages:GetMessages",
            "ec2messages:SendReply"
            ],
            "Resource" : "*"
        },
        {
            "Effect" : "Allow",
            "Action" : [
            "eks:DescribeCluster",
            "eks:ListClusters",
            "eks:AccessKubernetesApi"
            ],
            "Resource" : "*"
        },
        {
            "Sid" : "AmazonEKSWorkerNodePolicyExtra",
            "Effect" : "Allow",
            "Action" : [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource" : "*"
        },
        {
            "Sid" : "AmazonSSMManagedInstanceCoreExtra",
            "Effect" : "Allow",
            "Action" : [
            "ssm:UpdateInstanceInformation",
            "ssm:ListInstanceAssociations",
            "ssm:DescribeInstanceProperties",
            "ssm:DescribeAssociation",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetDocument",
            "ssm:DescribeDocument",
            "ssm:GetManifest",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:ListAssociations",
            "ssm:PutInventory",
            "ssm:PutComplianceItems",
            "ssm:PutConfigurePackageResult",
            "ssm:UpdateAssociationStatus",
            "ssm:UpdateInstanceAssociationStatus"
            ],
            "Resource" : "*"
        }
        ]
    }
    }

    # campushub-karpentercontroller-policy
    karpenterController_policy = {
      name = "campushub-karpentercontroller-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement: [
            {
                "Sid": "AllowScopedEC2InstanceAccessActions",
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:ec2:ap-northeast-2::image/*",
                    "arn:aws:ec2:ap-northeast-2::snapshot/*",
                    "arn:aws:ec2:ap-northeast-2:*:security-group/*",
                    "arn:aws:ec2:ap-northeast-2:*:subnet/*",
                    "arn:aws:ec2:ap-northeast-2:*:capacity-reservation/*"
                ],
                "Action": [
                    "ec2:RunInstances",
                    "ec2:CreateFleet"
                ]
            },
            {
                "Sid": "AllowScopedEC2LaunchTemplateAccessActions",
                "Effect": "Allow",
                "Resource": "arn:aws:ec2:ap-northeast-2:*:launch-template/*",
                "Action": [
                    "ec2:RunInstances",
                    "ec2:CreateFleet"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned"
                    },
                    "StringLike": {
                        "aws:ResourceTag/karpenter.sh/nodepool": "*"
                    }
                }
            },
            {
                "Sid": "AllowScopedEC2InstanceActionsWithTags",
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:ec2:ap-northeast-2:*:fleet/*",
                    "arn:aws:ec2:ap-northeast-2:*:instance/*",
                    "arn:aws:ec2:ap-northeast-2:*:volume/*",
                    "arn:aws:ec2:ap-northeast-2:*:network-interface/*",
                    "arn:aws:ec2:ap-northeast-2:*:launch-template/*",
                    "arn:aws:ec2:ap-northeast-2:*:spot-instances-request/*",
                    "arn:aws:ec2:ap-northeast-2:*:capacity-reservation/*"
                ],
                "Action": [
                    "ec2:RunInstances",
                    "ec2:CreateFleet",
                    "ec2:CreateLaunchTemplate"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                        "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}"
                    },
                    "StringLike": {
                        "aws:RequestTag/karpenter.sh/nodepool": "*"
                    }
                }
            },
            {
                "Sid": "AllowScopedResourceCreationTagging",
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:ec2:ap-northeast-2:*:fleet/*",
                    "arn:aws:ec2:ap-northeast-2:*:instance/*",
                    "arn:aws:ec2:ap-northeast-2:*:volume/*",
                    "arn:aws:ec2:ap-northeast-2:*:network-interface/*",
                    "arn:aws:ec2:ap-northeast-2:*:launch-template/*",
                    "arn:aws:ec2:ap-northeast-2:*:spot-instances-request/*"
                ],
                "Action": "ec2:CreateTags",
                "Condition": {
                    "StringEquals": {
                        "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                        "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}",
                        "ec2:CreateAction": [
                            "RunInstances",
                            "CreateFleet",
                            "CreateLaunchTemplate"
                        ]
                    },
                    "StringLike": {
                        "aws:RequestTag/karpenter.sh/nodepool": "*"
                    }
                }
            },
            {
                "Sid": "AllowScopedResourceTagging",
                "Effect": "Allow",
                "Resource": "arn:aws:ec2:ap-northeast-2:*:instance/*",
                "Action": "ec2:CreateTags",
                "Condition": {
                    "StringEquals": {
                        "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned"
                    },
                    "StringLike": {
                        "aws:ResourceTag/karpenter.sh/nodepool": "*"
                    },
                    "StringEqualsIfExists": {
                        "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}"
                    },
                    "ForAllValues:StringEquals": {
                        "aws:TagKeys": [
                            "eks:eks-cluster-name",
                            "karpenter.sh/nodeclaim",
                            "Name"
                        ]
                    }
                }
            },
            {
                "Sid": "AllowScopedDeletion",
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:ec2:ap-northeast-2:*:instance/*",
                    "arn:aws:ec2:ap-northeast-2:*:launch-template/*"
                ],
                "Action": [
                    "ec2:TerminateInstances",
                    "ec2:DeleteLaunchTemplate"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned"
                    },
                    "StringLike": {
                        "aws:ResourceTag/karpenter.sh/nodepool": "*"
                    }
                }
            },
            {
                "Sid": "AllowRegionalReadActions",
                "Effect": "Allow",
                "Resource": "*",
                "Action": [
                    "ec2:DescribeCapacityReservations",
                    "ec2:DescribeImages",
                    "ec2:DescribeInstances",
                    "ec2:DescribeInstanceTypeOfferings",
                    "ec2:DescribeInstanceTypes",
                    "ec2:DescribeLaunchTemplates",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeSpotPriceHistory",
                    "ec2:DescribeSubnets"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:RequestedRegion": var.region
                    }
                }
            },
            {
                "Sid": "AllowSSMReadActions",
                "Effect": "Allow",
                "Resource": "arn:aws:ssm:ap-northeast-2::parameter/aws/service/*",
                "Action": "ssm:GetParameter"
            },
            {
                "Sid": "AllowPricingReadActions",
                "Effect": "Allow",
                "Resource": "*",
                "Action": "pricing:GetProducts"
            },
            {
                "Sid": "AllowInterruptionQueueActions",
                "Effect": "Allow",
                "Resource": "arn:aws:sqs:${var.region}:${var.aws_account_id}:${var.cluster_name}",
                "Action": [
                    "sqs:DeleteMessage",
                    "sqs:GetQueueUrl",
                    "sqs:ReceiveMessage"
                ]
            },
            {
                "Sid": "AllowPassingInstanceRole",
                "Effect": "Allow",
                "Resource": "arn:aws:iam::${var.aws_account_id}:role/campushub-karpenterNode-role",
                "Action": "iam:PassRole",
                "Condition": {
                    "StringEquals": {
                        "iam:PassedToService": [
                            "ec2.amazonaws.com",
                            "ec2.amazonaws.com.cn"
                        ]
                    }
                }
            },
            {
                "Sid": "AllowScopedInstanceProfileCreationActions",
                "Effect": "Allow",
                "Resource": "arn:aws:iam::${var.aws_account_id}:instance-profile/*",
                "Action": [
                    "iam:CreateInstanceProfile"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                        "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}",
                        "aws:RequestTag/topology.kubernetes.io/region": var.region
                    },
                    "StringLike": {
                        "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
                    }
                }
            },
            {
                "Sid": "AllowScopedInstanceProfileTagActions",
                "Effect": "Allow",
                "Resource": "arn:aws:iam::${var.aws_account_id}:instance-profile/*",
                "Action": [
                    "iam:TagInstanceProfile"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                        "aws:ResourceTag/topology.kubernetes.io/region": var.region,
                        "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                        "aws:RequestTag/eks:eks-cluster-name": "${var.cluster_name}",
                        "aws:RequestTag/topology.kubernetes.io/region": var.region
                    },
                    "StringLike": {
                        "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*",
                        "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
                    }
                }
            },
            {
                "Sid": "AllowScopedInstanceProfileActions",
                "Effect": "Allow",
                "Resource": "arn:aws:iam::${var.aws_account_id}:instance-profile/*",
                "Action": [
                    "iam:AddRoleToInstanceProfile",
                    "iam:RemoveRoleFromInstanceProfile",
                    "iam:DeleteInstanceProfile"
                ],
                "Condition": {
                    "StringEquals": {
                        "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}": "owned",
                        "aws:ResourceTag/topology.kubernetes.io/region": "ap-northeast-2"
                    },
                    "StringLike": {
                        "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*"
                    }
                }
            },
            {
                "Sid": "AllowInstanceProfileReadActions",
                "Effect": "Allow",
                "Resource": "arn:aws:iam::${var.aws_account_id}:instance-profile/*",
                "Action": "iam:GetInstanceProfile"
            },
            {
                "Sid": "AllowAPIServerEndpointDiscovery",
                "Effect": "Allow",
                "Resource": "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.cluster_name}",
                "Action": "eks:DescribeCluster"
            }
        ]
    }
    }

    # campushub-monitoring-policy
    monitoring_policy = {
      name = "campushub-monitoring-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement: [
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
    }
    }

    # campushub-lambda-policy - Aurora DB 작업용 최소 권한
    lambda_policy = {
      name = "campushub-lambda-policy"
      policy_json = {
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ]
            Resource = "arn:aws:logs:${var.region}:${var.aws_account_id}:*"
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:AttachNetworkInterface",
            "ec2:DetachNetworkInterface"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "kms:Decrypt"
            ]
            Resource = "*"
            Condition = {
            StringEquals = {
                "kms:ViaService": "secretsmanager.${var.region}.amazonaws.com"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "rds:DescribeDBClusters",
            "rds:DescribeDBInstances"
            ]
            Resource = "*"
        }
        ]
    }
    }

    # campushub-git-actions-policy
    # Campus Hub Git Actions Policy
    git_actions_policy = {
      name = "campushub-lambda-policy"
      policy_json = {
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
    }
    }


  }
}
}