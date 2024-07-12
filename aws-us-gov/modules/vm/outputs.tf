output "vm_target_private_ip" {
  value = aws_instance.vm_target.private_ip
}

output "vm_target_public_ip" {
  value = aws_instance.vm_target.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.target_key.private_key_pem
  sensitive = true
}

output "vm_attacker_private_ip" {
  value = aws_instance.vm_attacker.private_ip
}

output "vm_attacker_public_ip" {
  value = aws_instance.vm_attacker.public_ip
}