locals {
  karpenter_namespace = "karpenter"
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true
  namespace             = local.karpenter_namespace

  # EC2NodeClass에서 쓸 노드 IAM Role 이름
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "${var.prefix}-karpenter-node-role"

  # MNG 환경이니까 기본 Pod Identity 사용 (Fargate가 아니라면 IRSA 안 써도 됨)
  create_pod_identity_association = true
}



data "aws_iam_policy_document" "karpenter_passrole" {
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::${var.account_id}:role/${var.prefix}-eks-karpenter-node",
    ]
  }
}

resource "aws_iam_policy" "karpenter_passrole" {
  name        = "KarpenterControllerPassRole"
  description = "Allow KarpenterController to PassRole to Karpenter node role"

  policy = data.aws_iam_policy_document.karpenter_passrole.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_passrole" {
  role       = module.karpenter.iam_role_name  # <- Karpenter 컨트롤러 Role
  policy_arn = aws_iam_policy.karpenter_passrole.arn
}
