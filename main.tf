terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }

    utils = {
      source  = "cloudposse/utils"
      version = ">= 0.17.0"
    }
  }

  backend "s3" {}
}

module "network" {
  source               = "./modules/network"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  enable_nat           = var.enable_nat
  prefix               = var.prefix
}

module "sg" {
  source   = "./modules/sg"
  vpc_id   = module.network.vpc_id
  vpc_cidr = var.vpc_cidr
}

# module "keypair" {
#   source = "./modules/keypair"
#   prefix = var.prefix
# }

# module "jenkins" {
#   source        = "./modules/jenkins"
#   ami_id        = var.docker_ami_id
#   instance_type = var.jenkins_instance_type
#   prefix        = var.prefix
#   subnet_id     = module.network.private_subnet_a_id
#   vpc_id        = module.network.vpc_id
#   key_name      = module.keypair.key_name
#   az            = var.azs[0]
#   sg_id         = module.sg.backend_sg_id
# }

# module "alb_jenkins" {
#   source             = "./modules/alb_jenkins"
#   vpc_id             = module.network.vpc_id
#   alb_sg_id          = module.sg.alb_sg_id
#   subnet_ids         = module.network.public_subnet_ids
#   target_instance_id = module.jenkins.instance_id
#   prefix             = "${var.prefix}-jenkins"

#   depends_on = [module.jenkins]
# }

# module "alb_service" {
#   source       = "./modules/alb"
#   vpc_id       = module.network.vpc_id
#   alb_sg_id    = module.sg.alb_sg_id
#   subnet_ids   = module.network.public_subnet_ids
#   prefix       = "${var.prefix}-service"
#   active_color = var.gateway_active_color
#   # acm_certificate_arn = var.acm_certificate_arn
# }

# module "bastion" {
#   source        = "./modules/bastion"
#   ami_id        = var.ubuntu_ami_id
#   instance_type = var.bastion_instance_type
#   subnet_id     = module.network.public_subnet_a_id
#   sg_id         = module.sg.bastion_sg_id
#   key_name      = module.keypair.key_name
#   prefix        = var.prefix
# }

# RDS
module "rds" {
  source            = "./modules/rds"
  prefix            = "${var.prefix}-db"
  subnet_ids        = module.network.db_subnet_ids
  vpc_id            = module.network.vpc_id
  sg_id             = module.sg.rds_sg_id
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version
  db_name           = var.rds_db_name
  username          = var.rds_username
  password          = var.rds_password
  port              = var.rds_port
}

module "elasticache" {
  source         = "./modules/elasticache"
  prefix         = var.prefix
  subnet_ids     = module.network.db_subnet_ids
  sg_id          = module.sg.redis_sg_id
  azs            = var.azs
  engine_version = var.elasticache_engine_version
  node_type      = var.elasticache_node_type
  auth_token     = var.elasticache_auth_token
}

module "ssm" {
  source = "./modules/ssm"

  parameters = {
    "/${var.prefix}/jwt/JWT_ACCESS_TOKEN_PRIVATE_KEY" = var.jwt_access_token_private_key
    "/${var.prefix}/jwt/JWT_ACCESS_TOKEN_PUBLIC_KEY"  = var.jwt_access_token_public_key
    "/${var.prefix}/jwt/JWT_REFRESH_TOKEN_SECRET"     = var.jwt_refresh_secret
    "/${var.prefix}/rds/POSTGRESQL_PASSWORD"          = var.rds_password
    "/${var.prefix}/redis/DATA_REDIS_PASSWORD"        = var.elasticache_auth_token
    "/${var.prefix}/payment/TOSSPAYMENTS_SECRET_KEY"  = var.toss_secret
    "/${var.prefix}/ai/GEMINI_API_KEY"                = var.gemini_api_key
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  ############################
  # 1. 클러스터 기본 설정
  ############################
  cluster_name    = "come2us-eks"
  cluster_version = "1.30"

  # 엔드포인트 접근 (ECS도 내부 FARGATE였으니 private 중심 가정)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # 제어 플레인 로그 (ECS에서 CloudWatch 쓰던 맥락)
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  ############################
  # 2. 네트워크 (기존 VPC 재사용)
  ############################
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  ############################
  # 3. IAM / aws-auth
  ############################
  enable_irsa = true  # ECS Task Role → IRSA로 옮기기 위한 전제

  ############################
  # 4. 워커 (ECS Fargate → EKS NodeGroup 버전)
  ############################
  eks_managed_node_groups = {
    infra_ng = {
      min_size     = 2
      max_size     = 6
      desired_size = 2

      instance_types = ["t3.medium"] 
      ami_type = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND" 

      labels = {
        node_type = "infra"
        capacity = "on_demand"
        "karpenter.sh/controller" = "true"
      }

      tags = {
        Name = "come2us-infra-node"
      }

      taints = [
        {
          key = "node_type"
          value = "infra"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    app_ng = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"] # or t3.small
      ami_type = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND" 

      labels = {
        node_type = "app"
        capacity = "on_demand"
      }

      tags = {
        Name = "come2us-app-node"
      }
      
      iam_role_additional_policies = {
        aws_load_balancer_controller = aws_iam_policy.aws_load_balancer_controller.arn
      }
    }
  }

  
  node_security_group_tags = {
    "karpenter.sh/discovery" = "come2us-eks"
  } 

  ############################
  # 5. 필수 Addons
  ############################
  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          {
            key      = "node_type"
            operator = "Equal"
            value    = "infra"
            effect   = "NoSchedule"
          }
        ]
        nodeSelector = {
          node_type = "infra"
        }
      })
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

  ############################
  # 6. 공통 태그
  ############################
  tags = {
    Project = "come2us"
    Env     = "prod"
    Stack   = "eks"
  }

    # KMS + Secret 암호화 끄기
  create_kms_key                  = false
  cluster_encryption_config       = {}
  attach_cluster_encryption_policy = false
}

resource "aws_security_group_rule" "allow_istiod_webhook_from_control_plane" {
  # 1. 수신지 (Destination): EKS 노드 그룹의 보안 그룹 ID (워커 노드 SG)
  # eks 모듈은 기본적으로 노드 그룹 간 공유되는 하나의 보안 그룹을 생성하고 ID를 출력합니다.
  security_group_id = module.eks.node_security_group_id 
  
  type              = "ingress"
  from_port         = 15017
  to_port           = 15017
  protocol          = "tcp"
  description       = "Allow EKS Control Plane to Istiod webhook on 15017"

  # 2. 발신지 (Source): EKS 클러스터 Control Plane의 보안 그룹 ID
  # Control Plane이 워커 노드로 트래픽을 보낼 때 이 SG를 소스로 사용합니다.
  source_security_group_id = module.eks.cluster_security_group_id
  
  # Note: 이 규칙은 'infra_ng'와 'app_ng'를 포함한 모든 EKS 관리형 노드 그룹에 적용됩니다.
}

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
  node_iam_role_name            = "come2us-karpenter-node-role"

  # MNG 환경이니까 기본 Pod Identity 사용 (Fargate가 아니라면 IRSA 안 써도 됨)
  create_pod_identity_association = true
}

data "aws_ecrpublic_authorization_token" "karpenter" {
  provider = aws.us_east_1
}

# Karpenter 컨트롤러가 Karpenter 노드 롤을 PassRole 할 수 있도록 허용

data "aws_iam_policy_document" "karpenter_passrole" {
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::997784788329:role/come2us-eks-karpenter-node",
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


resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = local.karpenter_namespace
  create_namespace = true

  repository          = "oci://public.ecr.aws/karpenter"
  # repository_username = data.aws_ecrpublic_authorization_token.karpenter.user_name
  # repository_password = data.aws_ecrpublic_authorization_token.karpenter.password
  chart               = "karpenter"
  version             = "1.0.2" 
  wait                = false

  values = [
    <<-EOT
    # 1. Controller Pod가 infra_ng 노드 그룹으로 스케줄링되도록 강제
    nodeSelector:
      karpenter.sh/controller: 'true'
    tolerations:
      - key: node_type
        operator: Equal
        value: infra
        effect: NoSchedule
        
    # 2. 필수 설정
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}

    # 3. IRSA (혹은 Pod Identity) 연결 설정
    serviceAccount:
      annotations:
        # Pod Identity를 사용하더라도, Pod Identity Agent가 이 annotation을 사용해 권한을 부여합니다.
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn} 
        
    webhook:
      enabled: false
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

module "aws_msk_cluster" {
  source = "./modules/msk"

  cluster_name           = "come2us-msk"
  kafka_version          = "3.8.x.kraft"
  number_of_broker_nodes = 4

  instance_type = "kafka.m7g.large"
  client_subnets = module.network.db_subnet_ids
  volume_size = 20
  
  security_groups = [module.sg.kafka_sg_id]
}

module "iam" {
  source        = "./modules/iam"
  cluster_name  = module.eks.cluster_name
  account_id    = "997784788329"
  eks_admin_user = "terraform-access"
}

module "route53" {
  source = "./modules/route53"

  domain_name = "come2us.store"
}

# ALB 컨트롤러가 사용할 ELB 관련 권한
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "AWSLoadBalancerControllerPolicy"
  description = "Permissions for AWS Load Balancer Controller running on app_ng nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

variable "argocd_host" {
  type        = string
  description = "FQDN for ArgoCD server"
  default     = "argocd.come2us.store"
}

variable "argocd_acm_arn" {
  type        = string
  description = "ACM certificate ARN for ArgoCD HTTPS"
  default     = "arn:aws:acm:ap-northeast-2:997784788329:certificate/4f5f4057-92b3-45a3-94e3-13c3d1f873be"
}

# 1. Namespace
resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argo"
  }
}

locals {
  argocd_tolerations = [
    {
      key      = "node_type"
      operator = "Equal"
      value    = "infra"
      effect   = "NoSchedule"
    }
  ]

  argocd_node_selector = {
    node_type = "infra"
  }
}

# 2. ArgoCD 설치 (Helm)
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argo.metadata[0].name
  version    = "5.34.5"

  values = [
    jsonencode({
      controller = {
        tolerations = local.argocd_tolerations
        nodeSelector = local.argocd_node_selector
      }
      server = {
        tolerations = local.argocd_tolerations
        nodeSelector = local.argocd_node_selector
      }
      repoServer = {
        tolerations = local.argocd_tolerations
        nodeSelector = local.argocd_node_selector
      }
      applicationSet = {
        tolerations = local.argocd_tolerations
        nodeSelector = local.argocd_node_selector
      }
      dex = {
        tolerations = local.argocd_tolerations
        nodeSelector = local.argocd_node_selector
      }
    })
  ]
}
