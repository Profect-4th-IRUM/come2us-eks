variable "project_name" {
  default = "come2us"
}

variable "environment" {
  description = "환경 이름 (e.g., dev, stage, prod)"
  type        = string
  default     = "prod"
}

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