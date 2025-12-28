# 임시 노드그룹용 IAM 역할
resource "aws_iam_role" "temp_nodegroup_role" {
  name = "temp-nodegroup-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  
      }
    }]
    Version = "2012-10-17"
  })
}

# 필수 정책 연결
resource "aws_iam_role_policy_attachment" "temp_nodegroup_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.temp_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "temp_nodegroup_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.temp_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "temp_nodegroup_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.temp_nodegroup_role.name
}

# 임시 노드그룹용 Launch Template
resource "aws_launch_template" "temp_nodegroup_lt" {
  name_prefix = "temp-nodegroup-lt-"

  network_interfaces {
    security_groups = [
      module.sg_nodegroup.security_group_id
    ]
  }
}

# 임시 관리형 노드그룹 - Add-on 설치용
resource "aws_eks_node_group" "temp_nodegroup" {
  cluster_name    = module.eks-cluster.cluster_name
  node_group_name = "temp-nodegroup"
  node_role_arn   = aws_iam_role.temp_nodegroup_role.arn
  
  subnet_ids = [
    module.vpc.private_subnet_ids_by_az_index[0][0],  # private-a-1
    module.vpc.private_subnet_ids_by_az_index[1][0]   # private-c-1  
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.temp_nodegroup_lt.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2  
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  # 노드그룹 교체 시 먼저 삭제 후 생성하도록 명시 (이름 충돌 방지)
  lifecycle {
    create_before_destroy = false
  }

  # Add-on 설치 완료 후 제거 예정
  depends_on = [
    module.eks-cluster,
    aws_iam_role.temp_nodegroup_role,
    module.vpc
  ]


  tags = {
    Name = "temp-nodegroup-for-addons"
    Purpose = "temporary"
    AutoDelete = "after-karpenter-ready"
  }
}
