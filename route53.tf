
# 기존 Route53 도메인 데이터 소스 (기존 Hosted Zone 사용)
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Private Hosted Zone (VPC 내부용)
resource "aws_route53_zone" "private" {
  name = var.internal_domain
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

# 기존 ACM SSL 인증서 사용 (새로 생성하지 않음)
data "aws_acm_certificate" "main" {
  domain      = "*.${var.domain_name}"  # *.campushub.cloud
  statuses    = ["ISSUED"]
  most_recent = true
}

# Aurora DNS 
resource "aws_route53_record" "aurora_writer" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "aurora.${var.internal_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_cluster.campus-hub-aurora.endpoint]

  depends_on = [
    aws_rds_cluster.campus-hub-aurora,
    aws_route53_zone.private
  ]
}

# Aurora Reader DNS (읽기 전용 엔드포인트)
resource "aws_route53_record" "aurora_reader" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "aurora-reader.${var.internal_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_cluster.campus-hub-aurora.reader_endpoint]

  depends_on = [
    aws_rds_cluster.campus-hub-aurora,
    aws_route53_zone.private
  ]
}

# STS VPC Endpoint DNS (IRSA 토큰 발급용)
resource "aws_route53_record" "sts_endpoint" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "sts.${var.internal_domain}"
  type    = "A"
  
  alias {
    name                   = aws_vpc_endpoint.sts.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.sts.dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [
    aws_vpc_endpoint.sts,
    aws_route53_zone.private
  ]
}

# STS 표준 도메인도 VPC Endpoint로 연결 (ESO용)
resource "aws_route53_record" "sts_standard" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "sts.${var.region}.amazonaws.com"
  type    = "A"
  
  alias {
    name                   = aws_vpc_endpoint.sts.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.sts.dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [
    aws_vpc_endpoint.sts,
    aws_route53_zone.private
  ]
}

# Secrets Manager 표준 도메인도 VPC Endpoint로 연결
resource "aws_route53_record" "secretsmanager_standard" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "secretsmanager.${var.region}.amazonaws.com"
  type    = "A"
  
  alias {
    name                   = aws_vpc_endpoint.secretsmanager.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.secretsmanager.dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [
    aws_vpc_endpoint.secretsmanager,
    aws_route53_zone.private
  ]
}

# 필수 출력값
output "route53_name_servers" {
  description = "Route53 네임서버 목록 (기존 도메인)"
  value       = data.aws_route53_zone.main.name_servers
}

output "ssl_certificate_arn" {
  description = "SSL 인증서 ARN (ALB/NLB에서 사용)"
  value       = data.aws_acm_certificate.main.arn
}

