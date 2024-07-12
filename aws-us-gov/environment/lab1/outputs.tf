# Outputs from the vpc module
output "vpc_id_target" {
  value = module.vpc.vpc_id_target
}

output "vpc_id_attacker" {
  value = module.vpc.vpc_id_attacker
}

output "public_subnet_attacker" {
  value = module.vpc.public_subnet_attacker
}

output "public_subnet_target" {
  value = module.vpc.public_subnet_target
}

output "public_rt_attacker" {
  value = module.vpc.public_rt_attacker
}

output "public_rt_target" {
  value = module.vpc.public_rt_target
}

output "cidr_block_attacker" {
  value = module.vpc.cidr_block_attacker
}

output "cidr_block_target" {
  value = module.vpc.cidr_block_target
}

# Outputs from the vm module
output "vm_target_private_ip" {
  value = module.vm.vm_target_private_ip
}

output "vm_target_public_ip" {
  value = module.vm.vm_target_public_ip
}

output "private_key_pem" {
  value     = module.vm.private_key_pem
  sensitive = true
}

output "vm_attacker_private_ip" {
  value = module.vm.vm_attacker_private_ip
}

output "vm_attacker_public_ip" {
  value = module.vm.vm_attacker_public_ip
}

# Outputs from the s3 module
output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

# Outputs from the vm module
output "target_private_key" {
  value     = module.vm.target_private_key
  sensitive = true
}
