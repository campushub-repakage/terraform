data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "sg_nlb" {
  source      = "./modules/security-group"
  name        = "campushub-sg-NLB"
  description = "for NLB Server"
  vpc_id      = module.vpc.vpc_id
  cluster_name = var.cluster_name

  ingress_rules = [
    { description = "allow HTTP", from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "allow HTTPS", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]

  egress_rules = [
    { description = "allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

module "sg_cluster" {
  source      = "./modules/security-group"
  name        = "campushub-sg-cluster"
  description = "for EKS Cluster API Server"
  vpc_id      = module.vpc.vpc_id
  cluster_name = var.cluster_name

  ingress_rules = []  # 빈 규칙으로 설정

  egress_rules = [
    { description = "allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

module "sg_nodegroup" {
  source      = "./modules/security-group"
  name        = "campushub-sg-nodegroup"
  description = "for EKS Worker Nodes"
  vpc_id      = module.vpc.vpc_id
  cluster_name = var.cluster_name

  ingress_rules = [
    # 애플리케이션 트래픽
    { description = "allow HTTP from VPC", from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow HTTPS from VPC", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow custom app port 8080", from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow ArgoCD repo server", from_port = 8081, to_port = 8081, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow webhook admission controller", from_port = 8443, to_port = 8443, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    
    # Kubernetes 통신
    { description = "allow kubelet API", from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    
    # 모니터링 통신
    { description = "allow grafana", from_port = 3000, to_port = 3000, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow prometheus", from_port = 9090, to_port = 9090, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow argocd dashboard", from_port = 3100, to_port = 3100, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },


    # DNS & Service Discovery (VPC 내부 - CoreDNS 등)
    { description = "allow DNS TCP", from_port = 53, to_port = 53, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow DNS UDP", from_port = 53, to_port = 53, protocol = "udp", cidr_blocks = ["10.0.0.0/16"] },
    
    # Istio
    { description = "allow Istio", from_port = 15021, to_port = 15021, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow Istio Pilot", from_port = 15017, to_port = 15017, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] },
    { description = "allow Istio Citadel", from_port = 15012, to_port = 15012, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] }
  ]

  egress_rules = [
    { description = "allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# karpenter discovery 태그 부여
resource "aws_ec2_tag" "sg_nodegroup_discovery" {
  resource_id = module.sg_nodegroup.security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
  
  depends_on = [module.sg_nodegroup]
}

# Aurora 보안그룹 생성 (EKS 워커 노드에서만 접근)
module "sg_aurora" {
  source      = "./modules/security-group"
  name        = "campushub-sg-aurora"
  description = "for aurora Server"
  vpc_id      = module.vpc.vpc_id
  cluster_name = var.cluster_name

  ingress_rules = []  # 빈 규칙으로 설정

  egress_rules = [
    { description = "allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# Aurora 접근을 EKS 워커 노드에서만 허용
resource "aws_security_group_rule" "aurora_from_eks_nodes" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.sg_nodegroup.security_group_id
  security_group_id        = module.sg_aurora.security_group_id
  description              = "allow Aurora from EKS worker nodes only"
}

# Aurora 접근을 Bastion에서 허용
resource "aws_security_group_rule" "aurora_from_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.campushub-sg-bastion.id
  security_group_id        = module.sg_aurora.security_group_id
  description              = "allow Aurora from bastion host"
}

# VPC Endpoints 보안그룹 생성 (EKS 워커 노드에서만 접근)
module "sg_vpc_endpoints" {
  source      = "./modules/security-group"
  name        = "campushub-sg-vpc-endpoints"
  description = "for VPC Endpoints"
  vpc_id      = module.vpc.vpc_id
  cluster_name = var.cluster_name

  ingress_rules = []  # 빈 규칙으로 설정

  egress_rules = [
    { description = "allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# VPC Endpoints 접근을 EKS 워커 노드에서만 허용
resource "aws_security_group_rule" "vpc_endpoints_from_eks_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.sg_nodegroup.security_group_id
  security_group_id        = module.sg_vpc_endpoints.security_group_id
  description              = "allow VPC Endpoints from EKS worker nodes only"
}

# EKS 클러스터 접근을 워커 노드에서만 허용
resource "aws_security_group_rule" "cluster_api_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.sg_nodegroup.security_group_id
  security_group_id        = module.sg_cluster.security_group_id
  description              = "allow EKS API access from worker nodes only"
}

# Kubelet API 접근을 클러스터에서만 허용
resource "aws_security_group_rule" "kubelet_from_cluster" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = module.sg_cluster.security_group_id
  security_group_id        = module.sg_nodegroup.security_group_id
  description              = "allow kubelet API access from EKS cluster only"
}

# Pod 간 통신 (같은 보안그룹 내에서만)
resource "aws_security_group_rule" "pod_to_pod_communication" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.sg_nodegroup.security_group_id
  security_group_id        = module.sg_nodegroup.security_group_id
  description              = "allow pod to pod communication within EKS worker nodes"
}