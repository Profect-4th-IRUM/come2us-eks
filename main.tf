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

module "bastion" {
  source        = "./modules/bastion"
  ami_id        = var.ubuntu_ami_id
  instance_type = var.bastion_instance_type
  subnet_id     = module.network.public_subnet_a_id
  sg_id         = module.sg.bastion_sg_id
  prefix        = var.prefix
}

# RDS
module "rds" {
  source            = "./modules/rds"
  prefix            = "${var.prefix}-db"
  environment       = var.environment
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
  environment    = var.environment 
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
# module "aws_msk_cluster" {
#   source = "./modules/msk"

#   cluster_name           = "come2us-msk"
#   kafka_version          = "3.8.x.kraft"
#   number_of_broker_nodes = 4

#   instance_type = "kafka.m7g.large"
#   client_subnets = module.network.db_subnet_ids
#   volume_size = 20
  
#   security_groups = [module.sg.kafka_sg_id]
# }

module "route53" {
  source = "./modules/route53"

  domain_name = "come2us.store"
}
