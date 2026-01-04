# 공개 도메인 정보
output "domain_info" {
  description = "도메인 설정 정보"
  value = {
    domain       = var.domain_name
    name_servers = data.aws_route53_zone.main.name_servers
  }
}

# 내부 서비스 엔드포인트
output "internal_services" {
  description = "VPC 내부 서비스 DNS (애플리케이션 설정에 사용)"
  value = {
    database = {
      writer   = "aurora.${var.internal_domain}"
      reader   = "aurora-reader.${var.internal_domain}"
      port     = 3306
      database = aws_rds_cluster.campus-hub-aurora.database_name
    }
    aws_services = {
      sts_endpoint = "sts.${var.internal_domain}"
      s3_region    = "${var.region}"
      dynamodb_region = "${var.region}"
    }
    tables = {
      attendance_records  = aws_dynamodb_table.attendance_records.name
      students           = aws_dynamodb_table.students.name
      attendance_summary = aws_dynamodb_table.attendance_summary.name
      attendance_sessions = aws_dynamodb_table.attendance_sessions.name
    }
  }
}

# 애플리케이션 설정값
output "app_config" {
  description = "애플리케이션에서 사용할 설정값들"
  value = {
    DB_HOST         = "aurora.${var.internal_domain}"
    DB_READER_HOST  = "aurora-reader.${var.internal_domain}"
    DB_PORT         = "3306"
    DB_NAME         = aws_rds_cluster.campus-hub-aurora.database_name
    DYNAMODB_TABLE  = aws_dynamodb_table.attendance_records.name
    AWS_STS_ENDPOINT = "https://sts.${var.internal_domain}"
  }
}

# IAM 역할 정보
output "iam_roles" {
  description = "IRSA 역할 ARN들"
  value = {
    eso_role_arn = module.campushub-eso-role.role_arn
    lbc_role_arn = module.campushub-IRSA-lbc-role.role_arn
    external_dns_role_arn = module.external_dns_role.role_arn
  }
}
