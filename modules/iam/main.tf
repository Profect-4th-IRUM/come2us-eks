locals {
  karpenter_node_role_name             = "${var.cluster_name}-karpenter-node"
  karpenter_node_instance_profile_name = local.karpenter_node_role_name
}

data "aws_iam_policy_document" "karpenter_passrole" {
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::997784788329:role/come2us-eks-karpenter-node",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

####################################################
# 1. Karpenter 노드용 IAM Role
####################################################
resource "aws_iam_role" "karpenter_node" {
  name = local.karpenter_node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

####################################################
# 2. Karpenter 노드 필수 Managed Policies
####################################################
resource "aws_iam_role_policy_attachment" "karpenter_node_eks_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr_read" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 선택 – SSM Session Manager 사용 가능
resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

####################################################
# 3. Instance Profile (EC2가 Role을 쓰도록)
####################################################
resource "aws_iam_instance_profile" "karpenter_node" {
  name = local.karpenter_node_instance_profile_name
  role = aws_iam_role.karpenter_node.name
}

####################################################
# 4. EKS Access Entry (kubectl 권한 부여)
####################################################
resource "aws_eks_access_entry" "terraform_access" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:user/${var.eks_admin_user}"
  type          = "STANDARD"
}

####################################################
# 5. Access Policy 연결 (cluster admin 권한 부여)
####################################################
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
  principal_arn = "arn:aws:iam::${var.account_id}:role/terraform-access-role"
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

####################################################
# 6. Karpenter 노드용 EKS Access Entry (노드 조인 권한)
####################################################
resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name = var.cluster_name

  # 위에서 만든 Karpenter 노드 Role ARN 사용
  principal_arn = aws_iam_role.karpenter_node.arn

  # EC2 리눅스 노드 타입
  type = "EC2_LINUX"
}


