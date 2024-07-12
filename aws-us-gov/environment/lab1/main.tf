module "vpc" {
  source = "../../modules/vpc"

  cidr_block_attacker = "10.10.0.0/16"
  public_subnet_attacker = "10.10.0.0/24"
  vpc_name_attacker = "external-vpc"
  cidr_block_target = "10.0.0.0/16"
  public_subnet_target = "10.0.0.0/24"
  vpc_name_target = "internal-vpc"
}

module "vpc_peering" {
  source = "../../modules/vpc_peering"

  vpc_id_attacker      = module.vpc.vpc_id_attacker
  vpc_id_target        = module.vpc.vpc_id_target
  peering_name         = "external-to-internal-peering"
  cidr_block_attacker  = module.vpc.cidr_block_attacker
  cidr_block_target    = module.vpc.cidr_block_target
  public_rt_attacker   = module.vpc.public_rt_attacker
  public_rt_target     = module.vpc.public_rt_target
}

module "vm" {
  source = "../../modules/vm"
  # Attacker Kali VM
  ami_attacker_01 = "ami-0781eff9a68fb8c58"
  instance_type_attacker = "t3.medium"
  subnet_id_attacker = module.vpc.public_subnet_attacker
  vpc_id_attacker = module.vpc.vpc_id_attacker
  attacker_vm_name = "black-cat-00"
  volume_size_attacker = 64
  # Target Ubuntu VM
  ami_target_01 = "ami-0d6411bfafd0c6156"
  instance_type_target = "t3.micro"
  subnet_id_target = module.vpc.public_subnet_target
  vpc_id_target = module.vpc.vpc_id_target
  target_vm_name = "white-cat-00"
  volume_size_target = 16

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              useradd -m -s /bin/bash marty
              usermod -aG docker marty
              password=$(openssl rand -base64 12)
              echo "marty:$password" | chpasswd
              echo "$password" > /home/marty/password.txt
              chown marty:marty /home/marty/password.txt
              chmod 600 /home/marty/password.txt
              EOF

}

module "s3" {
  source = "../../modules/s3"
  bucket_name = "pt-lab-bucket-00"
  # Optionally define a custom bucket policy or use the default one
  # bucket_policy = file("path/to/custom_policy.json")
}