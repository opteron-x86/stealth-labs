provider "random" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Fetch the first available AZ in the region
data "aws_availability_zones" "available" {}

# Define the selected AZ (can also be hardcoded)
variable "selected_az" {
  default = "us-gov-east-1a"
  #default = data.aws_availability_zones.available.names[0]
}

resource "random_id" "attacker_vpc_name" {
  byte_length = 4
  prefix      = "external-vpc-"
}

resource "random_id" "target_vpc_name" {
  byte_length = 4
  prefix      = "internal-vpc-"
}

resource "random_integer" "attacker_cidr_block" {
  min = 0
  max = 255
}

resource "random_integer" "target_cidr_block" {
  min = 0
  max = 255
}

locals {
  attacker_cidr_block = "10.${random_integer.attacker_cidr_block.result}.0.0/16"
  attacker_subnet     = "10.${random_integer.attacker_cidr_block.result}.0.0/24"
  target_cidr_block   = "10.${random_integer.target_cidr_block.result}.0.0/16"
  target_subnet       = "10.${random_integer.target_cidr_block.result}.0.0/24"
}


module "vpc" {
  source = "../modules/vpc"

  cidr_block_attacker    = local.attacker_cidr_block
  public_subnet_attacker = local.attacker_subnet
  vpc_name_attacker      = random_id.attacker_vpc_name.hex
  cidr_block_target      = local.target_cidr_block
  public_subnet_target   = local.target_subnet
  availability_zone      = var.selected_az
  vpc_name_target        = random_id.target_vpc_name.hex
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
  allowed_cidr_blocks = ["149.88.105.233/32", module.vpc.cidr_block_target]
  ingress_rules = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    },
    {
      from_port = 8080
      to_port   = 8081
      protocol  = "tcp"
    },
    {
      from_port = 7777
      to_port   = 7788
      protocol  = "tcp"
    }
  ]
}

module "security_group_target" {
  source = "../modules/sg"

  vpc_id              = module.vpc.vpc_id_target
  allowed_cidr_blocks = [module.vpc.cidr_block_attacker]
  ingress_rules = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    },
    {
      from_port = 8080
      to_port   = 8081
      protocol  = "tcp"
    }
  ]
}

resource "aws_s3_bucket" "flask_app_bucket" {
  bucket = "flask-app-templates"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_object" "web_templates" {
  for_each = fileset("${path.module}/templates", "*")

  bucket = aws_s3_bucket.flask_app_bucket.bucket
  key    = each.value
  source = "${path.module}/templates/${each.value}"
}

resource "aws_iam_role" "canteen_ec2_role" {
  name = "canteen_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "canteen_access_policy" {
  name        = "canteen_access_policy"
  description = "Allow Canteen Lab to access the S3 bucket amd EBS volumes"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws-us-gov:s3:::flask-app-templates",
                "arn:aws-us-gov:s3:::flask-app-templates/*"
            ]
        },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeVolumes",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeInstances"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
        ],
        "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.canteen_ec2_role.name
  policy_arn = aws_iam_policy.canteen_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.canteen_ec2_role.name
}

# Generate a random integer for the VM names
resource "random_integer" "vm_name_suffix" {
  min = 10
  max = 99
}

module "vm" {
  source = "../modules/vm"

  # Attacker Kali VM
  ami_attacker_01       = "ami-0781eff9a68fb8c58"
  instance_type_attacker = "t3.medium"
  subnet_id_attacker    = module.vpc.public_subnet_attacker
  vpc_id_attacker       = module.vpc.vpc_id_attacker
  security_group_attacker = module.security_group_attacker.security_group_id
  attacker_vm_name      = "black-cat-${random_integer.vm_name_suffix.result}"
  volume_size_attacker  = 64

  # Target Ubuntu VM
  ami_target_01       = "ami-0d6411bfafd0c6156"
  instance_type_target = "t3.micro"
  subnet_id_target    = module.vpc.public_subnet_target
  vpc_id_target       = module.vpc.vpc_id_target
  security_group_target = module.security_group_target.security_group_id
  target_vm_name      = "white-cat-${random_integer.vm_name_suffix.result}"
  volume_size_target  = 16
  user_data           = file("${path.module}/userdata.sh")
  availability_zone   = var.selected_az
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

# Attach the existing EBS volume to the target instance
resource "aws_volume_attachment" "target_ebs_attachment" {
  device_name = "/dev/sdf"
  volume_id   = "vol-072f0679c8217523e"
  instance_id = module.vm.target_instance_id
}