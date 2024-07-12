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
  count = length(var.public_subnet_target)
  vpc_id = aws_vpc.vpc_target.id
  cidr_block = element(var.public_subnet_target, count.index)

  tags = {
    Name = "${var.vpc_name_target}-public-${count.index}"
  }
}

resource "aws_internet_gateway" "igw_target" {
  vpc_id = aws_vpc.vpc_target.id
}

resource "aws_route_table" "route_table_target" {
  vpc_id = aws_vpc.vpc_target.id

  tags {
    Name = "Route Table for Target VPC"
  }
}

resource "aws_route" "route_table_target_route" {
  route_table_id            = aws_route_table.route_table_target.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw_target.id
}

resource "aws_route_table_association" "subnet_assoc_for_vpc_target" {
  count = length(var.public_subnet_target)
  subnet_id = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_rt_target.id
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