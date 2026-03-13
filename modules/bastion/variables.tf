variable "ami_id" {
  type        = string
  description = "AMI ID for Bastion"
}

variable "instance_type" {
  type        = string
  description = "Instance type for Bastion"
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID where Bastion is placed"
}

variable "sg_id" {
  type        = string
  description = "Security Group ID for Bastion"
}

variable "prefix" {
  type        = string
  description = "Name prefix for Bastion resources"
}
