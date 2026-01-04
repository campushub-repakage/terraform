data "aws_eks_cluster_auth" "campushub" {
  name = aws_eks_cluster.campushub.name
}

resource "aws_eks_cluster" "campushub" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP" # eks 접근방식 configmap/iam 둘다 허용
    bootstrap_cluster_creator_admin_permissions = true # 클러스터 처음 접근 가능
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
    endpoint_public_access  = false # 인터넷을 통한 접근차단
    endpoint_private_access = true # VPC 내부에서만 접근허용
  }

  # 클러스터 재생성 방지
  lifecycle {
    ignore_changes = [
      access_config
    ]
  }
}

resource "aws_iam_openid_connect_provider" "eks-cluster" {
  client_id_list = ["sts.amazonaws.com"]
  url             = aws_eks_cluster.campushub.identity[0].oidc[0].issuer
}
