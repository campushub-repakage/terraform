# Lambda 함수 생성 (빈 상태)
resource "aws_lambda_function" "update-classdays" {
  filename         = "lambda_function.zip"
  function_name    = "campushub-update-classdays"
  role            = aws_iam_role.campushub_lambda_role.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 128

  # VPC 설정 (Aurora DB 접근용)
  vpc_config {
    subnet_ids         = [
      module.vpc.private_subnet_ids_by_az_index[0][0],
      module.vpc.private_subnet_ids_by_az_index[1][0]
    ]
    security_group_ids = [module.sg_nodegroup.security_group_id]
  }

  # 환경 변수 (Aurora DB 연결 정보)
  environment {
    variables = {
      ENVIRONMENT = "production"
      PROJECT     = "campus-hub"
      DB_HOST     = "aurora.${var.internal_domain}"
      DB_PORT     = "3306"
      DB_NAME     = aws_rds_cluster.campus-hub-aurora.database_name
      DB_USER     = "admin"
      DB_SECRET_ARN = aws_rds_cluster.campus-hub-aurora.master_user_secret[0].secret_arn
      LOG_LEVEL   = "INFO"
    }
  }

  tags = {
    Name    = "campushub-update-classdays"
    Project = "campus-hub"
  }
}

# Lambda 함수 코드 (빈 상태)
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<EOF
import os
import boto3
import json
import base64
import logging
from datetime import date
from sqlalchemy import create_engine, Column, Integer, Date, String, SmallInteger, Boolean, ForeignKey
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.pool import NullPool
from botocore.exceptions import ClientError

# 로깅 설정
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Secrets Manager에서 DB 연결 정보 가져오기
def get_secret():
    """Secrets Manager에서 DB 연결 정보를 가져오기"""
    secret_name = os.getenv("SECRET_NAME", "campushub/common-secret")  # Secrets Manager의 Secret Name
    region_name = os.getenv("AWS_REGION", "ap-northeast-2")  # 지역을 환경 변수로 설정 (예: 서울 리전)

    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)

    try:
        # 비밀값 가져오기
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)

        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        else:
            secret = base64.b64decode(get_secret_value_response['SecretBinary'])

        # JSON 형식으로 반환된 비밀 정보를 파싱하여 반환
        return json.loads(secret)

    except ClientError as e:
        logger.error(f"Unable to retrieve secret from Secrets Manager: {e}")
        raise e

# 환경 변수에서 DB 연결 정보 가져오기
def get_database_url():
    """Secrets Manager에서 가져온 DB 연결 정보로 DB URL 생성"""
    secret = get_secret()

    db_host = os.getenv("DB_HOST", "43.200.184.131")  # RDS의 엔드포인트 (세팅된 경우)
    db_port = os.getenv("DB_PORT", "3306")
    db_name = os.getenv("DB_NAME", "campushub")
    db_username = secret.get("DB_USERNAME")
    db_password = secret.get("DB_PASSWORD")

    return f"mysql+pymysql://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}"

# 데이터베이스 엔진 생성 (Lambda 환경에 맞게 NullPool 사용)
DATABASE_URL = get_database_url()
engine = create_engine(
    DATABASE_URL,
    poolclass=NullPool,  # Lambda에서 연결 풀을 사용하지 않거나 NullPool을 사용
    echo=False
)

# 세션 팩토리 생성
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base 클래스 생성
Base = declarative_base()

# 데이터베이스 모델
class Class(Base):
    __tablename__ = 'Class'
    id = Column(Integer, primary_key=True)
    startDate = Column(Date)
    endDate = Column(Date)
    currentClassDays = Column(Integer, default=0)
    lastUpdatedDate = Column(Date)

class ClassDate(Base):
    __tablename__ = 'ClassDate'
    id = Column(Integer, primary_key=True)
    classId = Column(Integer, ForeignKey('Class.id'), nullable=False)
    dayOfWeek = Column(SmallInteger, nullable=False)  # 예시: 0=일요일, 6=토요일
    isActive = Column(Boolean, default=True)

class ClassSchedule(Base):
    __tablename__ = 'ClassSchedule'
    id = Column(Integer, primary_key=True)
    classId = Column(Integer, ForeignKey('Class.id'), nullable=False)
    scheduleType = Column(String)  # 'REFRESH' 또는 다른 값
    startDate = Column(Date)
    endDate = Column(Date)

# DB 세션 생성
def get_db():
    """Lambda에서 DB 세션 생성"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 수업 요일 확인 함수
def is_class_day_today(class_dates, today: date) -> bool:
    active_days = _build_active_weekday_set(class_dates)
    python_weekday = today.weekday()  # 0=월요일, 6=일요일
    db_weekday = _map_python_weekday_to_db_weekday(python_weekday)
    return db_weekday in active_days

def _map_python_weekday_to_db_weekday(python_weekday: int) -> int:
    return (python_weekday + 1) % 7

def _build_active_weekday_set(class_dates) -> set:
    return {cd.dayOfWeek for cd in class_dates if getattr(cd, "isActive", True)}

# 일일 진행률 업데이트 함수 (핸들러 함수로 수정)
def lambda_handler(event, context):
    """AWS Lambda에서 매일 자정에 실행되는 진행 일수 업데이트"""
    try:
        # DB 세션을 생성
        with next(get_db()) as db:
            today = date.today()
            updated_classes = 0

            # DB에서 모든 클래스를 조회
            classes = db.query(Class).all()
            for class_info in classes:
                if not class_info.startDate or not class_info.endDate:
                    continue

                # 수업 날짜 조회
                class_dates = db.query(ClassDate).filter(ClassDate.classId == class_info.id).all()
                if not class_dates:
                    continue

                # 오늘이 수업 요일이고 시작/종료 날짜 사이인지 확인
                if is_class_day_today(class_dates, today) and class_info.startDate <= today <= class_info.endDate:
                    
                    # REFRESH 스케줄이 오늘인 경우 해당 classId는 건너뜀
                    refresh_schedules = db.query(ClassSchedule).filter(
                        ClassSchedule.classId == class_info.id,
                        ClassSchedule.scheduleType == 'REFRESH',
                        ClassSchedule.startDate >= class_info.startDate,
                        ClassSchedule.endDate <= class_info.endDate
                    ).all()

                    if any(schedule.startDate <= today <= schedule.endDate for schedule in refresh_schedules):
                        logger.info(f"REFRESH 일정으로 인해 진행률 업데이트 건너뜀: classId {class_info.id}")
                        continue

                    # 마지막 업데이트 날짜가 오늘이 아니면 +1
                    if class_info.lastUpdatedDate != today:
                        class_info.currentClassDays += 1
                        class_info.lastUpdatedDate = today
                        updated_classes += 1

            # DB 커밋
            db.commit()
            logger.info(f"일일 진행률 업데이트 완료: {updated_classes}개 클래스 업데이트")

    except SQLAlchemyError as e:
        db.rollback()
        logger.error(f"일일 진행률 업데이트 실패: {str(e)}")
        raise Exception(f"일일 진행률 업데이트 실패: {str(e)}")
EOF
    filename = "index.py"
  }
}
