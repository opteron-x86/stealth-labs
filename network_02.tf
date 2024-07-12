resource "aws_vpc" "vpc_attacker" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Attacker VPC"
  }
}


resource "aws_subnet" "public_subnet_attacker" {
  vpc_id     = aws_vpc.vpc_attacker.id
  cidr_block = "20.0.1.0/24"

  tags = {
    Name = "Public Subnet of Attacker VPC"
  }
}


resource "aws_internet_gateway" "ig_attacker" {
  vpc_id = aws_vpc.vpc_attacker.id

  tags = {
    Name = "Internet Gateway of Attacker VPC"
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

resource "aws_route_table_association" "subnect_assoc_for_vpc_attacker" {
  subnet_id      = aws_subnet.public_subnet_attacker.id
  route_table_id = aws_route_table.new_rt_attacker.id
}

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

resource "aws_instance" "vm_kali" {
  ami           = "ami-0781eff9a68fb8c58"
  instance_type = "t3.medium"

  tags = {
    Name = "vm-kali"
  }

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet_attacker.id
  vpc_security_group_ids      = [aws_security_group.sg_attacker.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Setting up AWS CLI environment for the attacker"

    # Install AWS CLI
    sudo apt-get update
    sudo apt-get install -y awscli

    # Pre-configure AWS CLI with the keys
    aws configure set aws_access_key_id AKIAY4HWX4QXWCQCXIV7
    aws configure set aws_secret_access_key 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
    aws configure set region us-gov-east-1
  EOF

  root_block_device {
    volume_size = 64
    volume_type = "gp2"
  }
}

output "vm_kali_private_ip" {
  value = aws_instance.vm_kali.private_ip
}

output "vm_kali_public_ip" {
  value = aws_instance.vm_kali.public_ip
}
