module "vpc" {
  source = "../modules/vpc"

  cidr_block_attacker    = "10.10.0.0/16"
  public_subnet_attacker = "10.10.0.0/24"
  vpc_name_attacker      = "external-vpc"
  cidr_block_target      = "10.0.0.0/16"
  public_subnet_target   = "10.0.0.0/24"
  vpc_name_target        = "internal-vpc"
}

module "vpc_peering" {
  source = "../modules/vpc_peering"
  peering_name         = "external-to-internal-peering"
  vpc_id_attacker = module.vpc.vpc_id_attacker
  vpc_id_target   = module.vpc.vpc_id_target
  cidr_block_attacker  = module.vpc.cidr_block_attacker
  cidr_block_target    = module.vpc.cidr_block_target
  public_rt_attacker   = module.vpc.public_rt_attacker
  public_rt_target     = module.vpc.public_rt_target
}

module "security_group_attacker" {
  source = "../modules/sg"

  vpc_id              = module.vpc.vpc_id_attacker
  allowed_cidr_blocks = ["62.10.29.38/32"]
  ingress_rules = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    },
    {
      from_port = 8081
      to_port   = 8081
      protocol  = "tcp"
    }
  ]
}

module "security_group_target" {
  source = "../modules/sg"

  vpc_id              = module.vpc.vpc_id_target
  allowed_cidr_blocks = ["10.10.0.0/16"]  # Allow all traffic from attacker VPC
  ingress_rules = [
    {
      from_port = 0-65535
      to_port   = 0-65535
      protocol  = "tcp"
    }
  ]
}

module "vm" {
  source = "../modules/vm"

  # Attacker Kali VM
  ami_attacker_01       = "ami-0781eff9a68fb8c58"
  instance_type_attacker = "t3.medium"
  subnet_id_attacker    = module.vpc.public_subnet_attacker
  vpc_id_attacker       = module.vpc.vpc_id_attacker
  security_group_attacker = module.security_group_attacker.security_group_id
  attacker_vm_name      = "black-cat-00"
  volume_size_attacker  = 64

  # Target Ubuntu VM
  ami_target_01       = "ami-0d6411bfafd0c6156"
  instance_type_target = "t3.micro"
  subnet_id_target    = module.vpc.public_subnet_target
  vpc_id_target       = module.vpc.vpc_id_target
  security_group_target = module.security_group_target.security_group_id
  target_vm_name      = "broker-cat-00"
  volume_size_target  = 16
  user_data           = file("${path.module}/userdata.sh")
}