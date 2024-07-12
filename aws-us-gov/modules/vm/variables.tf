variable "ami_target_01" {
  description = "Target AMI ID"
  type = string
}

variable "instance_type_target" {
  description = "Instance Type"
  type = string
}

variable "ami_attacker_01" {
  description = "Attacker AMI ID"
  type = string
}

variable "instance_type_attacker" {
  description = "Attacker Instance type"
  type = string
}

variable "subnet_id_attacker" {
  description = "Attacker subnet ID"
  type = string
}

variable "vpc_id_attacker" {
  description = "Attacker VPC ID"
  type = string
}

variable "attacker_vm_name" {
  description = "Name of the attacker VM"
  type = string
}

variable "volume_size_attacker" {
  description = "Size of the root EBS volume for attacker VM"
  type = number
  default = 64
}

variable "subnet_id_target" {
  description = "Target subnet ID"
  type = string
}

variable "vpc_id_target" {
  description = "Target VPC ID"
  type = string
}

variable "target_vm_name" {
  description = "Name of the target VM"
  type = string
}

variable "volume_size_target" {
  description = "Size of the root EBS volume for target VM"
  type = number
  default = 16
}

variable "user_data" {
  description = "User data to configure the instance"
  type        = string
  default     = ""
}
