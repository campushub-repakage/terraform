# DynamoDB 테이블 - 출석 기록 (메인 테이블)
resource "aws_dynamodb_table" "attendance_records" {
  name           = "StudentAttendance"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "studentId"
  range_key      = "classId#date"

  attribute {
    name = "studentId"
    type = "N"
  }

  attribute {
    name = "classId#date"
    type = "S"
  }

  # Global Secondary Index - 날짜별 조회
  global_secondary_index {
    name            = "date-index"
    hash_key        = "classId#date"
    projection_type = "ALL"
  }

  # Global Secondary Index - 수업별 조회
  global_secondary_index {
    name            = "classId-date-index"
    hash_key        = "classId#date"
    range_key       = "studentId"
    projection_type = "ALL"
  }

  # Global Secondary Index - 학생별 조회
  global_secondary_index {
    name            = "studentId-index"
    hash_key        = "studentId"
    range_key       = "classId#date"
    projection_type = "ALL"
  }

  # 백업 설정
  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name    = "attendance-records"
    Project = "campus-hub"
  }
}


# 세션 저장용 테이블 (예시)
resource "aws_dynamodb_table" "user_sessions" {
  name           = "user-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  # TTL 설정 (세션 자동 만료)
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name        = "user-sessions-table"

    Project     = "campus-hub"
  }
}


# 학생 정보 테이블
resource "aws_dynamodb_table" "students" {
  name           = "students"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "studentId"

  attribute {
    name = "studentId"
    type = "N"  # Number
  }

  # Point-in-time Recovery
  point_in_time_recovery {
    enabled = true
  }

  # 서버 사이드 암호화 설정
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "students-table"

    Project     = "campus-hub"
  }
}

# 출석 통계 테이블 (집계 데이터용)
resource "aws_dynamodb_table" "attendance_summary" {
  name           = "attendance-summary"
  billing_mode   = "PAY_PER_REQUEST"
  
  # Partition Key: 학생ID#월 (예: "123#2024-01")
  hash_key       = "studentId#month"
  
  attribute {
    name = "studentId#month"
    type = "S"
  }

  # studentId별 조회를 위한 GSI
  attribute {
    name = "studentId"
    type = "N"
  }

  # Global Secondary Index - 학생별 통계 조회
  global_secondary_index {
    name            = "studentId-index"
    hash_key        = "studentId"
    projection_type = "ALL"
  }

  # Point-in-time Recovery
  point_in_time_recovery {
    enabled = true
  }

  # 서버 사이드 암호화 설정
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "attendance-summary-table"

    Project     = "campus-hub"
  }
}

# 실시간 출석 세션 테이블 (현재 진행 중인 출석체크)
resource "aws_dynamodb_table" "attendance_sessions" {
  name           = "attendance-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  
  # Partition Key: 세션 ID (예: "class-2025-08-11-09-00")
  hash_key       = "session_id"
  
  attribute {
    name = "session_id"
    type = "S"
  }

  # TTL 설정 (캐시 자동 만료)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # 백업 설정
  point_in_time_recovery {
    enabled = true
  }

  # 서버 사이드 암호화 설정
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "attendance-sessions"
    Project     = "campus-hub"
  }
}

# 필수 출력값
output "dynamodb_tables" {
  description = "DynamoDB 테이블 이름 목록 (애플리케이션에서 사용)"
  value = {
    attendance_records = aws_dynamodb_table.attendance_records.name
    students          = aws_dynamodb_table.students.name
    attendance_summary = aws_dynamodb_table.attendance_summary.name
    attendance_sessions = aws_dynamodb_table.attendance_sessions.name
  }
}