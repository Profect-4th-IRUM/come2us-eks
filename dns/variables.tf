variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "terraform_role_arn" {
  description = "Terraform IAM role ARN"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "come2us.store"
}

variable "prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "come2us"
}
