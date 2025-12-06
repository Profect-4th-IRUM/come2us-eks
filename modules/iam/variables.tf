variable "cluster_name" {
  type = string
}

variable "account_id" {
  type = string
}

# kubectl로 EKS 관리하는 IAM User 이름 (terraform-access 등)
variable "eks_admin_user" {
  type = string
}

