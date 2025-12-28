# S3 게이트웨이 엔드포인트 생성
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    module.vpc.public_route_table_id,
    module.vpc.private_route_table_id
  ]

  tags = {
    Name = "campushub-s3-gateway-endpoint"
  }
}

# DynamoDB 게이트웨이 엔드포인트 생성
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    module.vpc.public_route_table_id,
    module.vpc.private_route_table_id
  ]

  tags = {
    Name = "campushub-dynamodb-gateway-endpoint"
  }
}

# STS VPC Endpoint (IRSA용 - 필수)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    module.vpc.private_subnet_ids_by_az_index[0][0],
    module.vpc.private_subnet_ids_by_az_index[1][0]
  ]
  
  security_group_ids = [module.sg_vpc_endpoints.security_group_id]
  private_dns_enabled = false
  
  tags = {
    Name = "campushub-sts-vpc-endpoint-private"
  }
}

# Secrets Manager VPC Endpoint (ESO용 - 필수)
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    module.vpc.private_subnet_ids_by_az_index[0][0],
    module.vpc.private_subnet_ids_by_az_index[1][0]
  ]
  
  security_group_ids = [module.sg_vpc_endpoints.security_group_id]
  private_dns_enabled = false
  
  tags = {
    Name = "campushub-secretsmanager-vpc-endpoint"
  }
}