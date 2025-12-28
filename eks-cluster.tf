module "eks-cluster" {
  source = "./modules/eks-cluster"

  cluster_name        = var.cluster_name
  cluster_version     = "1.32"
  cluster_role_arn = module.eks_cluster_role.role_arn
  subnet_ids = [
    module.vpc.private_subnet_ids_by_az_index[0][0],
    module.vpc.private_subnet_ids_by_az_index[1][0]
  ]

  security_group_ids = [
    module.sg_cluster.security_group_id,
    data.aws_security_group.default.id
  ]

  depends_on = [
    module.vpc,
    module.sg_cluster
  ]
}

# Bastion 역할에 EKS 클러스터 접근 권한 부여
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = module.eks-cluster.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/campushub-bastion-role"
  type          = "STANDARD"

  depends_on = [module.eks-cluster]
}

# Bastion 역할에 클러스터 관리자 정책 연결
resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = module.eks-cluster.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/campushub-bastion-role"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion]
}

# 현재 계정 정보 가져오기
data "aws_caller_identity" "current" {}

# 1. Amazon EKS Pod Identity Agent Add-on
resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = module.eks-cluster.cluster_name
  addon_name   = "eks-pod-identity-agent"  # 정확한 addon 이름
  
  # 충돌 해결 설정
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  # 타임아웃 설정
  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }
  
  # DEGRADED 상태도 정상으로 처리
  lifecycle {
    ignore_changes = [
      addon_version,
      tags
    ]
    create_before_destroy = true
  }
  
  depends_on = [
    module.eks-cluster,
    aws_eks_node_group.temp_nodegroup
  ]
}

# 2. Metrics Server Add-on (리소스 사용량 모니터링)
resource "aws_eks_addon" "metrics_server" {
  cluster_name = module.eks-cluster.cluster_name
  addon_name   = "metrics-server"
  
  # 충돌 해결 설정
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  # 타임아웃 설정
  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }
  
  # DEGRADED 상태도 정상으로 처리
  lifecycle {
    ignore_changes = [
      addon_version,
      tags 
    ]
    create_before_destroy = true
  }
  
  depends_on = [
    module.eks-cluster,
    aws_eks_node_group.temp_nodegroup
  ]
}