resource "aws_eip" "nat" {
  domain = "vpc"
}

module "vpc" {
  source      = "./modules/terraform-aws-vpc"
  name_prefix = "campushub"
  vpc_cidr    = "10.0.0.0/16"
  nat_eip_id  = aws_eip.nat.id
  cluster_name = var.cluster_name
  availability_zones = var.availability_zones

  public_subnet_config = {
    "public-a" = { cidr_block = "10.0.1.0/24", az = var.availability_zones[0] }
    "public-c" = { cidr_block = "10.0.3.0/24", az = var.availability_zones[1] }
  }

  private_subnet_config = {
    "private-a-1" = { cidr_block = "10.0.11.0/24", az = var.availability_zones[0] }
    "private-a-2" = { cidr_block = "10.0.21.0/24", az = var.availability_zones[0] }
    "private-c-1" = { cidr_block = "10.0.13.0/24", az = var.availability_zones[1] }
    "private-c-2" = { cidr_block = "10.0.23.0/24", az = var.availability_zones[1] }
  }
}