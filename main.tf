terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
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

# # RDS
# module "rds" {
#   source            = "./modules/rds"
#   prefix            = "${var.prefix}-db"
#   subnet_ids        = module.network.db_subnet_ids
#   vpc_id            = module.network.vpc_id
#   sg_id             = module.sg.rds_sg_id
#   instance_class    = var.rds_instance_class
#   allocated_storage = var.rds_allocated_storage
#   engine_version    = var.rds_engine_version
#   db_name           = var.rds_db_name
#   username          = var.rds_username
#   password          = var.rds_password
#   port              = var.rds_port
# }

# module "elasticache" {
#   source         = "./modules/elasticache"
#   prefix         = var.prefix
#   subnet_ids     = module.network.db_subnet_ids
#   sg_id          = module.sg.redis_sg_id
#   azs            = var.azs
#   engine_version = var.elasticache_engine_version
#   node_type      = var.elasticache_node_type
#   auth_token     = var.elasticache_auth_token
# }

# resource "aws_ecs_cluster" "come2us" {
#   name = "${var.prefix}-cluster"
# }

# module "ssm" {
#   source = "./modules/ssm"

#   parameters = {
#     "/${var.prefix}/config/GIT_USERNAME"             = var.git_username
#     "/${var.prefix}/config/GIT_TOKEN"                = var.git_token
#     "/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"     = var.jwt_access_secret
#     "/${var.prefix}/jwt/JWT_REFRESH_TOKEN_SECRET"    = var.jwt_refresh_secret
#     "/${var.prefix}/rds/POSTGRESQL_PASSWORD"         = var.rds_password
#     "/${var.prefix}/redis/DATA_REDIS_PASSWORD"       = var.elasticache_auth_token
#     "/${var.prefix}/payment/TOSSPAYMENTS_SECRET_KEY" = var.toss_secret
#     "/${var.prefix}/ai/GEMINI_API_KEY"               = var.gemini_api_key
#   }
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  ############################
  # 1. 클러스터 기본 설정
  ############################
  cluster_name    = "come2us-eks"
  cluster_version = "1.30"

  # 엔드포인트 접근 (ECS도 내부 FARGATE였으니 private 중심 가정)
  cluster_endpoint_public_access  = false
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
    backend = {
      min_size     = 2
      max_size     = 6
      desired_size = 2

      instance_types = ["t3.medium"] # or t3.small
      capacity_type  = "ON_DEMAND" 

      labels = {
        workload = "backend"
      }

      tags = {
        Name = "come2us-backend-node"
      }
    }
  }

  ############################
  # 5. 필수 Addons
  ############################
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

  ############################
  # 6. 공통 태그
  ############################
  tags = {
    Project = "come2us"
    Env     = "prod"
    Stack   = "eks-migration"
  }

    # 🔒 KMS + Secret 암호화 끄기
  create_kms_key                  = false
  cluster_encryption_config       = {}
  attach_cluster_encryption_policy = false
}
