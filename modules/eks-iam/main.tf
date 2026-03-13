resource "aws_eks_access_entry" "terraform_access" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:user/${var.eks_admin_user}"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform_access_admin" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.terraform_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.terraform_access
  ]
}

resource "aws_eks_access_entry" "terraform_role_access" {
  cluster_name  = var.cluster_name
  principal_arn = var.terraform_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform_role_admin" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.terraform_role_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.terraform_role_access
  ]
}
