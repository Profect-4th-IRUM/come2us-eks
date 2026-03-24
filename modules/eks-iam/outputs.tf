output "eks_admin_access_entry_principal" {
  value = aws_eks_access_entry.terraform_access.principal_arn
}
