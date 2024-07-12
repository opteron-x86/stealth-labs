# Attacker VPC resources
resource "aws_vpc" "vpc_attacker" {
  cidr_block           = var.cidr_block_attacker
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name_attacker
  }
}

resource "aws_subnet" "public_subnet_attacker" {
  count = length(var.public_subnet_attacker)
  vpc_id = aws_vpc.vpc_attacker.id
  cidr_block = element(var.public_subnet_attacker, count.index)

  tags = {
    Name = "${var.vpc_name_attacker}-public-${count.index}"
  }
}

resource "aws_internet_gateway" "igw_attacker" {
  vpc_id = aws_vpc.vpc_attacker.id
}

resource "aws_route_table" "public_rt_attacker" {
  vpc_id = aws_vpc.vpc_attacker.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_attacker.id
  }
}

resource "aws_route_table" "new_rt_attacker" {
  vpc_id = aws_vpc.vpc_attacker.id

  tags = {
    Name = "New Route Table for Attacker VPC"
  }
}

resource "aws_route" "new_rt_02_route" {
  route_table_id         = aws_route_table.new_rt_attacker.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig_attacker.id
}

resource "aws_route_table_association" "subnet_assoc_for_vpc_attacker" {
  count = length(var.public_subnet_attacker)
  subnet_id = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_rt_attacker.id
}

# Security Group rule definitions
resource "aws_security_group" "sg_attacker" {
  name        = "kali-sg-vpc_attacker"
  description = "SG of Kali Instance in Attacker VPC"
  vpc_id      = aws_vpc.vpc_attacker.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}