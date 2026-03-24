module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  # 클러스터 기본 설정
  cluster_name    = "${var.prefix}-eks"
  cluster_version = "1.32"

  # 제어 플레인 로그 (ECS에서 CloudWatch 쓰던 맥락)
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  # 네트워크
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  # IAM
  enable_irsa = true

  # 워커 노드 설정
  eks_managed_node_groups = local.eks_managed_node_groups
  
  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.prefix}-eks"
  } 

  # Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  # 공통 태그
  tags = {
    Project = "${var.prefix}"
    Env     = "${var.environment}"
    Stack   = "eks"
  }
}