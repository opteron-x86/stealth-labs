resource "aws_instance" "vm_attacker" {
  ami           = var.ami_attacker_01
  instance_type = var.instance_type_attacker
  subnet_id     = var.subnet_id_attacker
  vpc_security_group_ids = [aws_security_group.vm_sg_attacker.id]

  tags = {
    Name = var.attacker_vm_name
  }
  associate_public_ip_address = true  # Assign public IP
  
  root_block_device {
    volume_size = var.volume_size_attacker
  }
}

resource "aws_security_group" "vm_sg_attacker" {
  vpc_id = var.vpc_id_attacker

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5901
    to_port     = 5901
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.attacker_vm_name}-sg"
  }
}

# Generate a new RSA key pair
resource "tls_private_key" "target_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an EC2 key pair using the generated public key
resource "aws_key_pair" "target_key_pair" {
  key_name   = "target-key-pair"
  public_key = tls_private_key.target_key.public_key_openssh
}


resource "aws_instance" "vm_target" {
  ami           = var.ami_target_01
  instance_type = var.instance_type_target
  key_name      = aws_key_pair.target_key_pair.key_name
  subnet_id     = var.subnet_id_target
  vpc_security_group_ids = [aws_security_group.vm_sg_target.id]

  associate_public_ip_address = true  # Assign public IP

  tags = {
    Name = var.target_vm_name
  }

  root_block_device {
    volume_size = var.volume_size_target
  }

  user_data = var.user_data
}

resource "aws_security_group" "vm_sg_target" {
  vpc_id = var.vpc_id_target

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.target_vm_name}-sg"
  }
}