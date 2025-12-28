# Internet Gateway
resource "aws_internet_gateway" "campushub" {
  vpc_id = aws_vpc.campushub.id
  tags = {
    Name = "${var.name_prefix}-igw"
  }
}


# NAT Gateway
resource "aws_nat_gateway" "campushub" {
  allocation_id = var.nat_eip_id
  subnet_id     = values(aws_subnet.public)[0].id
  tags = {
    Name = "${var.name_prefix}-natgw"
  }
  depends_on = [aws_internet_gateway.campushub]
}


# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.campushub.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.campushub.id
  }
  tags = {
    Name = "${var.name_prefix}-rtb-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = values(aws_subnet.public)[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.campushub.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.campushub.id
  }
  tags = {
    Name = "${var.name_prefix}-rtb-private"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id = values(aws_subnet.private)[count.index].id
  route_table_id = aws_route_table.private.id
}
