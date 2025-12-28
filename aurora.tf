# DB Subnet Group - Aurora 배포용 서브넷 그룹
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "campushub-aurora-subnet-group"
  subnet_ids = [
    module.vpc.private_subnet_ids_by_az_index[0][1],
    module.vpc.private_subnet_ids_by_az_index[1][1] 
  ]
  
  # 서브넷 그룹만 삭제 가능하도록 설정
  lifecycle {
    create_before_destroy = true
  }
}

# Aurora 클러스터
resource "aws_rds_cluster" "campus-hub-aurora" {
  cluster_identifier      = "${var.project_name}-aurora"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.11.5"
  database_name          = var.aurora_database_name
  master_username        = "admin"
  manage_master_user_password = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql_utf8mb4.name
  
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [module.sg_aurora.security_group_id]
  
  # 백업 설정
  # backup_retention_period      = 7
  # preferred_backup_window     = "03:00-04:00"
  # preferred_maintenance_window = "sun:04:00-sun:05:00"

  # 삭제 보호
  deletion_protection = false
  skip_final_snapshot = true

  depends_on = [
    aws_db_subnet_group.aurora_subnet_group,
    module.sg_aurora
  ]
}

# Aurora MySQL utf8mb4 parameter group
resource "aws_rds_cluster_parameter_group" "aurora_mysql_utf8mb4" {
  name        = "${var.project_name}-aurora-mysql-utf8mb4"
  family      = "aurora-mysql5.7"
  description = "Aurora MySQL cluster params for utf8mb4"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  # 한국어/한국 시간대 설정 및 연결 기본값
  parameter {
    name  = "lc_time_names"
    value = "ko_KR"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_connection"
    value = "utf8mb4_unicode_ci"
  }
}

# Aurora Writer 인스턴스
resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier         = "${var.project_name}-aurora-writer"
  cluster_identifier = aws_rds_cluster.campus-hub-aurora.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.campus-hub-aurora.engine
  engine_version     = aws_rds_cluster.campus-hub-aurora.engine_version

  # 백업 설정
  copy_tags_to_snapshot = true

  tags = {
    Name = "${var.project_name}-aurora-writer"
  }

  depends_on = [aws_rds_cluster.campus-hub-aurora]
}

# 필수 출력값 (내부 DNS 사용 권장)
output "aurora_config" {
  description = "Aurora 설정 정보 (애플리케이션에서 사용)"
  value = {
    host     = "aurora.${var.internal_domain}"  # 내부 DNS 사용
    database = aws_rds_cluster.campus-hub-aurora.database_name
    port     = 3306
  }
}

# Aurora 엔드포인트 출력
output "aurora_endpoint" {
  description = "Aurora writer endpoint"
  value       = aws_rds_cluster.campus-hub-aurora.endpoint
}