resource "aws_security_group" "campushub" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  # 인바운드 규칙을 직접 정의 (중복 자동 제거)
  dynamic "ingress" {
    for_each = { for rule in var.ingress_rules : "${rule.from_port}-${rule.to_port}-${rule.protocol}" => rule... }
    content {
      description = ingress.value[0].description
      from_port   = ingress.value[0].from_port
      to_port     = ingress.value[0].to_port
      protocol    = ingress.value[0].protocol
      cidr_blocks = distinct(flatten([for r in ingress.value : r.cidr_blocks]))
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