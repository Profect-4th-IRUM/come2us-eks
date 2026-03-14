resource "aws_iam_policy" "terraform_eks_policy" {
  name = "terraform-eks-policy"
  policy = templatefile("${path.module}/policy/terraform_eks_policy.json", {
    account_id = data.aws_caller_identity.current.account_id
    region     = var.region
  })
}

resource "aws_iam_role_policy_attachment" "terraform_eks_role_attach" {
  role       = aws_iam_role.terraform_access_role.name
  policy_arn = aws_iam_policy.terraform_eks_policy.arn
}

resource "aws_iam_user_policy_attachment" "terraform_eks_user_attach" {
  user       = aws_iam_user.terraform_access.name
  policy_arn = aws_iam_policy.terraform_eks_policy.arn
}
