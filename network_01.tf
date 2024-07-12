resource "aws_vpc" "vpc_target" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Target VPC"
  }
}

# Generate a new RSA key pair
resource "tls_private_key" "target_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an S3 bucket where the key will be stored
resource "aws_s3_bucket" "target_bucket" {
  bucket = "pt-lab-bucket"
  force_destroy = true
}

# Configure S3 bucket for website hosting
resource "aws_s3_bucket_website_configuration" "target_bucket_website" {
  bucket = aws_s3_bucket.target_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Create an S3 ACL that allows public read access
resource "aws_s3_bucket_public_access_block" "target_bucket" {
  bucket = aws_s3_bucket.target_bucket.id

  block_public_acls = false
  block_public_policy   = false
  ignore_public_acls    = false
  restrict_public_buckets   = false
}

# Set the ownership controls to the IAM owner
resource "aws_s3_bucket_ownership_controls" "target_bucket" {
  bucket = aws_s3_bucket.target_bucket.id
  rule {
    object_ownership    = "ObjectWriter"
  }
}

# Upload the private key to the misconfigured S3 bucket
resource "aws_s3_object" "target_key" {
  bucket = aws_s3_bucket.target_bucket.bucket
  key    = "target-key-pair.pem"
  content = tls_private_key.target_key.private_key_pem
  acl    = "public-read"
}

# Create an EC2 key pair using the generated public key
resource "aws_key_pair" "target_key_pair" {
  key_name   = "target-key-pair"
  public_key = tls_private_key.target_key.public_key_openssh
}


resource "aws_subnet" "public_subnet_target" {
  vpc_id     = aws_vpc.vpc_target.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet of Target VPC"
  }
}

resource "aws_internet_gateway" "ig_target" {
  vpc_id = aws_vpc.vpc_target.id

  tags = {
    Name = "Internet Gateway of Target VPC"
  }
}

resource "aws_route_table" "new_rt_target" {
  vpc_id = aws_vpc.vpc_target.id

  tags = {
    Name = "New Route Table for Target VPC"
  }
}

resource "aws_route" "new_rt_target_route" {
  route_table_id            = aws_route_table.new_rt_target.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.ig_target.id
}

resource "aws_route_table_association" "subnet_assoc_for_vpc_target" {
  subnet_id      = aws_subnet.public_subnet_target.id
  route_table_id = aws_route_table.new_rt_target.id
}

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

resource "aws_instance" "vm_target" {
  ami           = "ami-093d375659859241e"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.target_key_pair.key_name
  tags = {
    Name = "target-vm-01"
  }

  associate_public_ip_address = true
  subnet_id = aws_subnet.public_subnet_target.id
  vpc_security_group_ids = [
    aws_security_group.sg_target.id
  ]


  user_data = <<-EOF
    #!/bin/bash
    sleep 15
    echo "STEP: CREATE FLAG FILE"
    echo "FLAG # 1!" > /root/flag.txt

    sleep 15
    echo "STEP: SET UP SSH ACCESS"
    NEW_USER=adminuser
    adduser --disabled-password --gecos "" $NEW_USER
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers >/dev/null
    mkdir -p /home/$NEW_USER/.ssh
    chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
    chmod 700 /home/$NEW_USER/.ssh
    cp /home/ubuntu/.ssh/authorized_keys /home/$NEW_USER/.ssh/authorized_keys
    echo "$NEW_USER:password" | chpasswd
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh
  EOF

}

resource "aws_instance" "vm_target_02" {
  ami           = "ami-093d375659859241e"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.target_key_pair.key_name
  tags = {
    Name = "target-vm-02"
  }

  associate_public_ip_address = true
  subnet_id = aws_subnet.public_subnet_target.id
  vpc_security_group_ids = [
    aws_security_group.sg_target_02.id
  ]


  user_data = <<-EOF
    #!/bin/bash
    sleep 15
    echo "STEP: CREATE FLAG FILE"
    echo "FLAG # 2!" > /root/flag.txt

    sleep 15
    echo "STEP: SET UP SSH ACCESS"
    NEW_USER=adminuser2
    adduser --disabled-password --gecos "" $NEW_USER
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers >/dev/null
    mkdir -p /home/$NEW_USER/.ssh
    chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
    chmod 700 /home/$NEW_USER/.ssh
    cp /home/ubuntu/.ssh/authorized_keys /home/$NEW_USER/.ssh/authorized_keys
    echo "$NEW_USER:password" | chpasswd
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh
  EOF

}

output "vm_target_private_ip" {
  value = aws_instance.vm_target.private_ip
}

output "vm_target_public_ip" {
  value = aws_instance.vm_target.public_ip
}

output "vm_target_02_private_ip" {
  value = aws_instance.vm_target_02.private_ip
}

output "vm_target_02_public_ip" {
  value = aws_instance.vm_target_02.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.target_key.private_key_pem
  sensitive = true
}
