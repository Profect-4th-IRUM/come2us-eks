# provider
variable "region" {
  default = "ap-northeast-2"
}

variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
}

variable "terraform_role_arn" {
  description = "Terraform Role ARN"
}

# common
variable "prefix" {
  default     = "come2us"
  type        = string
  description = "project prefix for resource naming"
}

variable "environment" {
  description = "환경 이름 (e.g., dev, stage, prod)"
  type        = string
  default     = "prod"
}

# jenkins
variable "docker_ami_id" {
  type        = string
  description = "AWS Machine Images"
}

variable "jenkins_instance_type" {
  type        = string
  description = "Jenkins Instance Type"
}

# network
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs for RDS"
}

variable "enable_nat" {
  type        = bool
  description = "Enable NAT Gateway in public_a"
  default     = true
}

# bastion
variable "bastion_instance_type" {
  default = "t3.micro"
}

variable "ubuntu_ami_id" {
  type        = string
  description = "AMI for Bastion host"
  default     = "ami-0c9c942bd7bf113a2" # Ubuntu 22.04
}

# RDS
variable "rds_db_name" {
  type = string
}

variable "rds_instance_class" {
  default = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_engine_version" {
  type    = string
  default = "17.4"
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type      = string
  sensitive = true
}

variable "rds_port" {
  type    = number
  default = 5432
}

# ALB
variable "acm_certificate_arn" {
  description = "ACM Certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

# ElastiCache
variable "elasticache_engine_version" {
  type    = string
  default = "7.1"
}

variable "elasticache_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "elasticache_auth_token" {
  type      = string
  default   = null
  sensitive = true
}

# Profile
variable "spring_profile_active" {
  description = "Active Profile of Spring Application"
  type        = string
  default     = "prod"
}

# Git Config
variable "git_username" {
  description = "GIT_USERNAME"
  type        = string
}

variable "git_token" {
  description = "GIT_TOKEN"
  type        = string
}

# JWT Config
variable "jwt_access_token_private_key" {
  description = "JWT_ACCESS_TOKEN_PRIVATE_KEY"
  type        = string
}

variable "jwt_access_token_public_key" {
  description = "JWT_ACCESS_TOKEN_PUBLIC_KEY"
  type        = string
}

variable "jwt_refresh_secret" {
  description = "JWT REFRESH_TOKEN_SECRET"
  type        = string
}

variable "jwt_access_expiration_time" {
  description = "JWT_ACCESS_TOKEN_EXPIRATION_TIME"
  type        = number
  default     = 7200
}

variable "jwt_refresh_expiration_time" {
  description = "JWT_REFRESH_TOKEN_EXPIRATION_TIME"
  type        = number
  default     = 172800
}

variable "jwt_issuer" {
  description = "JWT_ISSUER"
  type        = string
  default     = "irum"
}

# Payment Config
variable "toss_secret" {
  description = "Toss Payments Secret Key"
  type        = string
}

# AI Config
variable "gemini_api_url" {
  description = "Gemini API URL"
  type        = string
}

variable "gemini_api_key" {
  description = "Gemini API KEY"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}