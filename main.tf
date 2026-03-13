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
