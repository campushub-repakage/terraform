# 로그 저장용 S3 버킷 생성
resource "aws_s3_bucket" "campus-hub-log" {
  bucket = var.log_bucket_name
}

# 로그 버킷 버전 관리
resource "aws_s3_bucket_versioning" "campus-hub-log" {
  bucket = aws_s3_bucket.campus-hub-log.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 로그 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "campus-hub-log" {
  bucket = aws_s3_bucket.campus-hub-log.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 로그 버킷 정책 (VPC Endpoint 연결)
resource "aws_s3_bucket_policy" "campus-hub-log" {
  bucket = aws_s3_bucket.campus-hub-log.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowLogAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:DeleteObject",
				  "s3:AbortMultipartUpload"
        ]
        Resource = [
          aws_s3_bucket.campus-hub-log.arn,
          "${aws_s3_bucket.campus-hub-log.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = module.vpc.vpc_id
          }
        }
      }
    ]
  })
}

# 로그 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "campus-hub-log" {
  bucket = aws_s3_bucket.campus-hub-log.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 로그 버킷 수명주기 정책
resource "aws_s3_bucket_lifecycle_configuration" "campus-hub-log" {
  bucket = aws_s3_bucket.campus-hub-log.id

  rule {
    id     = "log_lifecycle_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # 1달 후 Glacier로 이전
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    # 6개월 후 삭제
    expiration {
      days = 180
    }

    # 이전 버전 관리
    noncurrent_version_transition {
      noncurrent_days = 7
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# 로그 버킷 출력값
output "log_bucket_info" {
  description = "로그 S3 버킷 정보"
  value = {
    bucket_name = aws_s3_bucket.campus-hub-log.id
    bucket_arn  = aws_s3_bucket.campus-hub-log.arn
    domain_name = aws_s3_bucket.campus-hub-log.bucket_domain_name
  }
}
