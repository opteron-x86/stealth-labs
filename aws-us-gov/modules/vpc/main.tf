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
  vpc_id     = aws_vpc.vpc_attacker.id
  cidr_block = var.public_subnet_attacker
}

resource "aws_internet_gateway" "igw_attacker" {
  vpc_id = aws_vpc.vpc_attacker.id
}

resource "aws_route_table" "new_rt_attacker" {
  vpc_id = aws_vpc.vpc_attacker.id
}

resource "aws_route" "route_external" {
  route_table_id         = aws_route_table.new_rt_attacker.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_attacker.id
}

resource "aws_route_table_association" "subnet_assoc_for_vpc_attacker" {
  subnet_id      = aws_subnet.public_subnet_attacker.id
  route_table_id = aws_route_table.new_rt_attacker.id
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

# Target VPC resources
resource "aws_vpc" "vpc_target" {
  cidr_block           = var.cidr_block_target
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name_target
  }
}

resource "aws_subnet" "public_subnet_target" {
  vpc_id     = aws_vpc.vpc_target.id
  cidr_block = var.public_subnet_target
}

resource "aws_internet_gateway" "igw_target" {
  vpc_id = aws_vpc.vpc_target.id
}

resource "aws_route_table" "route_table_target" {
  vpc_id = aws_vpc.vpc_target.id
}

resource "aws_route" "route_table_target_route" {
  route_table_id         = aws_route_table.route_table_target.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_target.id
}

resource "aws_route_table_association" "subnet_assoc_for_vpc_target" {
  subnet_id      = aws_subnet.public_subnet_target.id
  route_table_id = aws_route_table.route_table_target.id
}

# Security Group rule definitions
resource "aws_security_group" "sg_target" {
  name        = "target-sg-vpc_target"
  description = "SG of Instance in Target VPC"
  vpc_id      = aws_vpc.vpc_target.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_target_02" {
  name        = "target-sg-02-vpc_target"
  description = "SG of Instance 02 in Target VPC"
  vpc_id      = aws_vpc.vpc_target.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_all_from_sg_target_to_target_02" {
  type                     = "ingress"
  description              = "Allow all from SG of Target Instance to Target Instance 02"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.sg_target.id
  security_group_id        = aws_security_group.sg_target_02.id
}