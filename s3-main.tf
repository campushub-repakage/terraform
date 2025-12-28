# S3 버킷 생성
resource "aws_s3_bucket" "campus-hub" {
  bucket = "campus-hub-bucket"
}

# S3 버킷 버전 관리
resource "aws_s3_bucket_versioning" "campus-hub" {
  bucket = aws_s3_bucket.campus-hub.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "campus-hub" {
  bucket = aws_s3_bucket.campus-hub.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 정책 - Pre-signed URL 지원
resource "aws_s3_bucket_policy" "campus-hub" {
  bucket = aws_s3_bucket.campus-hub.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSPreSignedURLGeneration"
        Effect = "Allow"
        Principal = {
          AWS = [
            module.campushub-IRSA-user-auth-role.role_arn,
            module.campus-hub-git-role.role_arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.campus-hub.arn}/*"
      }
    ]
  })
  
  depends_on = [
    aws_s3_bucket_public_access_block.campus-hub
  ]
}

# S3 버킷 퍼블릭 액세스 완전 차단 - Pre-signed URL만 허용
resource "aws_s3_bucket_public_access_block" "campus-hub" {
  bucket = aws_s3_bucket.campus-hub.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Intelligent Tiering 설정
resource "aws_s3_bucket_intelligent_tiering_configuration" "campus-hub" {
  bucket = aws_s3_bucket.campus-hub.id
  name   = "EntireBucket"

  filter {
    prefix = ""
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }

  status = "Enabled"
}

# S3 수명주기 정책 (Intelligent Tiering 적용)
resource "aws_s3_bucket_lifecycle_configuration" "campus-hub" {
  bucket = aws_s3_bucket.campus-hub.id

  rule {
    id     = "intelligent_tiering_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    # 이전 버전 관리
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

