resource "aws_security_group" "campushub" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  # 인바운드 규칙을 직접 정의
  dynamic "ingress" {
    for_each = { for i, r in var.ingress_rules : i => r }
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # 아웃바운드 규칙
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.name
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}