# Bastion Host용 서브넷 (VPC 모듈 출력 사용)
locals {
  bastion_subnet_id = module.vpc.public_subnet_ids[0]  # 첫 번째 public 서브넷 사용
}

# Bastion 서브넷 정보는 더 이상 필요하지 않음 (루트 볼륨 사용)

# 기존 키페어 사용
locals {
  key_pair_name = var.key_pair_name
}

# 보안그룹 생성
resource "aws_security_group" "campushub-sg-bastion" {
  name        = "campushub-sg-bastion"
  description = "for bastion Server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow custom app ports 8000-9000"
    from_port   = 8000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 아마존 리눅스 AMI 불러오기
data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion용 IAM 역할
resource "aws_iam_role" "campushub-bastion-role" {
  name = "campushub-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# AWS 관리형 정책 연결 - EKS 클러스터 관리
resource "aws_iam_role_policy_attachment" "campushub-bastion-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.campushub-bastion-role.name
}

# AWS 관리형 정책 연결 - EC2 읽기 권한
resource "aws_iam_role_policy_attachment" "campushub-bastion-ec2-readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.campushub-bastion-role.name
}

# AWS 관리형 정책 연결 - RDS 읽기 권한 (엔드포인트 자동 조회용)
resource "aws_iam_role_policy_attachment" "campushub-bastion-rds-readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  role       = aws_iam_role.campushub-bastion-role.name
}

# AWS 관리형 정책 연결 - SSM 읽기 권한
resource "aws_iam_role_policy_attachment" "bastion_ssm_getparam" {
  role       = aws_iam_role.campushub-bastion-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# Secrets Manager 및 KMS(Decrypt) 읽기 권한 부여 (RDS 마스터 비밀번호 조회용)
resource "aws_iam_role_policy" "bastion_secrets_kms_read" {
  name = "bastion-secrets-kms-read"
  role = aws_iam_role.campushub-bastion-role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

# 커스텀 정책 - 필수 권한들
resource "aws_iam_role_policy" "campushub-bastion-policy" {
  name = "campushub-bastion-policy"
  role = aws_iam_role.campushub-bastion-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "sts:AssumeRole", 
          "eks:*",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:PassRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Bastion Instance Profile
resource "aws_iam_instance_profile" "campushub-bastion-profile" {
  name = "campushub-bastion-profile"
  role = aws_iam_role.campushub-bastion-role.name
}

# Bastion EC2 인스턴스 생성
resource "aws_instance" "campushub-ec2-bastion" {
  ami                         = data.aws_ami.amazon-linux.id
  instance_type               = var.bastion_instance_type
  iam_instance_profile        = aws_iam_instance_profile.campushub-bastion-profile.name  # IAM 역할 연결
  vpc_security_group_ids = [
    aws_security_group.campushub-sg-bastion.id,
    data.aws_security_group.default.id
  ]
  subnet_id = local.bastion_subnet_id
  key_name                    = local.key_pair_name

  # 루트 볼륨 설정 (20GB)
  root_block_device {
    volume_size = var.bastion_ebs_volume_size
    volume_type = "gp3"
    encrypted   = true
    
    tags = {
      Name = "bastion-root-volume"
    }
  }

  # 메타데이터 서비스 설정 (IMDSv1/v2 모두 허용)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"  # IMDSv1도 허용
    http_put_response_hop_limit = 1
  }

    user_data = <<-EOF
    #!/bin/bash
    yum update -y
    
    # AWS CLI v2 설치 (이미 설치됨)
    # curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    # unzip awscliv2.zip
    # sudo ./aws/install
    
    # kubectl 설치
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    # Git 설치 (이미 설치됨)
    # yum install -y git
    
    # kubeconfig 설정 (EKS 클러스터 연결)
    aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}
    
    echo "Bastion host setup complete with kubectl, AWS CLI, and 20GB EBS volume mounted at /mnt/ebs"
    EOF

  tags = {
    Name = "bastion-ec2"
  }

  depends_on = [
    module.vpc,
    aws_iam_instance_profile.campushub-bastion-profile
  ]

  # On-Demand 인스턴스로 강제 교체
  lifecycle {
    create_before_destroy = true
  }
}

# EIP 할당
resource "aws_eip" "bastion_ip" {
  instance = aws_instance.campushub-ec2-bastion.id

  tags = {
    "Name" = "bastion_eip"
  }
}

# Basion IP 주소 출력
