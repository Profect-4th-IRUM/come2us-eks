terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

module "keypair" {
  source = "./modules/keypair"
  prefix = var.prefix
}

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

module "bastion" {
  source        = "./modules/bastion"
  ami_id        = var.ubuntu_ami_id
  instance_type = var.bastion_instance_type
  subnet_id     = module.network.public_subnet_a_id
  sg_id         = module.sg.bastion_sg_id
  key_name      = module.keypair.key_name
  prefix        = var.prefix
}

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

# resource "aws_ecs_cluster" "come2us" {
#   name = "${var.prefix}-cluster"
# }

# module "ecs_iam" {
#   source = "./modules/iam"
#   prefix = var.prefix
# }

module "ssm" {
  source = "./modules/ssm"

  parameters = {
    "/${var.prefix}/config/GIT_USERNAME"             = var.git_username
    "/${var.prefix}/config/GIT_TOKEN"                = var.git_token
    "/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"     = var.jwt_access_secret
    "/${var.prefix}/jwt/JWT_REFRESH_TOKEN_SECRET"    = var.jwt_refresh_secret
    "/${var.prefix}/rds/POSTGRESQL_PASSWORD"         = var.rds_password
    "/${var.prefix}/redis/DATA_REDIS_PASSWORD"       = var.elasticache_auth_token
    "/${var.prefix}/payment/TOSSPAYMENTS_SECRET_KEY" = var.toss_secret
    "/${var.prefix}/ai/GEMINI_API_KEY"               = var.gemini_api_key
  }
}

# # Cloud Map
# module "cloudmap" {
#   source = "./modules/cloudmap"

#   prefix = var.prefix
#   vpc_id = module.network.vpc_id
#   services = {
#     config  = {}
#     eureka  = {}
#     member  = {}
#     product = {}
#     order   = {}
#     payment = {}
#     ai      = {}
#   }
# }

# module "ecs_gateway" {
#   source = "./modules/ecs"

#   prefix        = "${var.prefix}-gateway"
#   cluster_name  = aws_ecs_cluster.come2us.name
#   subnets       = module.network.private_subnet_ids
#   backend_sg_id = module.sg.backend_sg_id

#   alb_target_group_blue  = module.alb_service.gateway_tg_blue_arn
#   alb_target_group_green = module.alb_service.gateway_tg_green_arn

#   image_tag_blue  = var.gateway_image_tag_blue
#   image_tag_green = var.gateway_image_tag_green

#   ecr_image      = "${var.ecr_uri}-gateway"
#   container_name = "${var.prefix}-gateway"
#   container_port = var.gateway_port
#   region         = var.region

#   profile_active     = var.spring_profile_active
#   config_server_host = "${module.cloudmap.service_names["config"]}.${module.cloudmap.namespace_name}"
#   config_server_port = var.config_port
#   eureka_host        = "${module.cloudmap.service_names["eureka"]}.${module.cloudmap.namespace_name}"
#   eureka_port        = var.eureka_port

#   active_color = var.gateway_active_color
#   warmup_color = var.gateway_warmup_color

#   execution_role_arn = module.ecs_iam.task_execution_role_arn
#   task_role_arn      = module.ecs_iam.task_role_arn

#   ssm_parameters = {
#     JWT_ACCESS_TOKEN_SECRET = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"]
#   }

#   depends_on = [module.ecs_config_server]
# }

# module "ecs_config_server" {
#   source = "./modules/ecs-single"

#   prefix        = "${var.prefix}-config"
#   cluster_name  = aws_ecs_cluster.come2us.name
#   subnets       = module.network.private_subnet_ids
#   backend_sg_id = module.sg.backend_sg_id

#   ecr_image      = "${var.ecr_uri}-config"
#   image_tag      = var.config_image_tag
#   container_name = "${var.prefix}-config"
#   container_port = var.config_port
#   region         = var.region

#   profile_active     = var.spring_profile_active
#   config_server_host = ""
#   config_server_port = var.config_port

#   execution_role_arn = module.ecs_iam.task_execution_role_arn
#   task_role_arn      = module.ecs_iam.task_role_arn

#   service_discovery_arn = module.cloudmap.service_arns["config"]

#   desired_count    = 2
#   assign_public_ip = false

#   ssm_parameters = {
#     GIT_USERNAME            = module.ssm.parameter_arns["/${var.prefix}/config/GIT_USERNAME"]
#     GIT_TOKEN               = module.ssm.parameter_arns["/${var.prefix}/config/GIT_TOKEN"]
#     JWT_ACCESS_TOKEN_SECRET = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"]
#   }
# }

# module "ecs_eureka" {
#   source = "./modules/ecs-single"

#   prefix        = "${var.prefix}-eureka"
#   cluster_name  = aws_ecs_cluster.come2us.name
#   subnets       = module.network.private_subnet_ids
#   backend_sg_id = module.sg.backend_sg_id

#   ecr_image      = "${var.ecr_uri}-eureka"
#   image_tag      = var.eureka_image_tag
#   container_name = "${var.prefix}-eureka"
#   container_port = var.eureka_port
#   region         = var.region

#   profile_active     = var.spring_profile_active
#   config_server_host = "${module.cloudmap.service_names["config"]}.${module.cloudmap.namespace_name}"
#   config_server_port = var.config_port
#   eureka_host        = "${module.cloudmap.service_names["eureka"]}.${module.cloudmap.namespace_name}"
#   eureka_port        = var.eureka_port

#   execution_role_arn = module.ecs_iam.task_execution_role_arn
#   task_role_arn      = module.ecs_iam.task_role_arn

#   service_discovery_arn = module.cloudmap.service_arns["eureka"]

#   desired_count    = 2
#   assign_public_ip = false

#   depends_on = [module.ecs_config_server]
# }

# module "ecs_member" {
#   source = "./modules/ecs-internal"

#   service_name = "${var.prefix}-member"
#   cluster_name = aws_ecs_cluster.come2us.name
#   region       = var.region

#   subnets            = module.network.private_subnet_ids
#   security_group_id  = module.sg.backend_sg_id
#   execution_role_arn = module.ecs_iam.task_execution_role_arn
#   task_role_arn      = module.ecs_iam.task_role_arn

#   ecr_image       = "${var.ecr_uri}-member"
#   image_tag_blue  = var.member_image_tag_blue
#   image_tag_green = var.member_image_tag_green
#   container_port  = var.member_port

#   active_color = var.member_active_color
#   warmup_color = var.member_warmup_color

#   service_discovery_arn = module.cloudmap.service_arns["member"]

#   environment = {
#     PROFILE_ACTIVE    = var.spring_profile_active
#     CONFIG_SERVER_URL = "http://${module.cloudmap.service_names["config"]}.${module.cloudmap.namespace_name}:${var.config_port}"
#     EUREKA_HOST       = "${module.cloudmap.service_names["eureka"]}.${module.cloudmap.namespace_name}"
#     EUREKA_PORT       = var.eureka_port

#     MEMBER_HOSTNAME = "${module.cloudmap.service_names["member"]}.${module.cloudmap.namespace_name}"
#     MEMBER_PORT     = var.member_port

#     WRITE_POSTGRESQL_HOST     = module.rds.rds_primary.address
#     WRITE_POSTGRESQL_PORT     = var.rds_port
#     WRITE_DB_NAME             = var.rds_db_name
#     WRITE_POSTGRESQL_USERNAME = var.rds_username

#     READ_POSTGRESQL_HOST     = module.rds.rds_primary.address
#     READ_POSTGRESQL_PORT     = var.rds_port
#     READ_DB_NAME             = var.rds_db_name
#     READ_POSTGRESQL_USERNAME = var.rds_username

#     DATA_REDIS_HOST = module.elasticache.session_redis.primary_address
#     DATA_REDIS_PORT = 6379

#     CACHE_REDIS_HOST = module.elasticache.cache_redis.address
#     CACHE_REDIS_PORT = 6379

#     JWT_ACCESS_TOKEN_EXPIRATION_TIME  = var.jwt_access_expiration_time
#     JWT_REFRESH_TOKEN_EXPIRATION_TIME = var.jwt_refresh_expiration_time
#     JWT_ISSUER                        = var.jwt_issuer
#   }

#   ssm_parameters = {
#     JWT_ACCESS_TOKEN_SECRET   = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"]
#     JWT_REFRESH_TOKEN_SECRET  = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_REFRESH_TOKEN_SECRET"]
#     WRITE_POSTGRESQL_PASSWORD = module.ssm.parameter_arns["/${var.prefix}/rds/POSTGRESQL_PASSWORD"]
#     READ_POSTGRESQL_PASSWORD  = module.ssm.parameter_arns["/${var.prefix}/rds/POSTGRESQL_PASSWORD"]
#     DATA_REDIS_PASSWORD       = module.ssm.parameter_arns["/${var.prefix}/redis/DATA_REDIS_PASSWORD"]
#   }
# }

# module "ecs_product" {
#   source = "./modules/ecs-internal"

#   service_name = "${var.prefix}-product"
#   cluster_name = aws_ecs_cluster.come2us.name
#   region       = var.region

#   subnets            = module.network.private_subnet_ids
#   security_group_id  = module.sg.backend_sg_id
#   execution_role_arn = module.ecs_iam.task_execution_role_arn
#   task_role_arn      = module.ecs_iam.task_role_arn

#   ecr_image       = "${var.ecr_uri}-product"
#   image_tag_blue  = var.product_image_tag_blue
#   image_tag_green = var.product_image_tag_green
#   container_port  = var.product_port

#   active_color = var.product_active_color
#   warmup_color = var.product_warmup_color

#   service_discovery_arn = module.cloudmap.service_arns["product"]

#   environment = {
#     PROFILE_ACTIVE    = var.spring_profile_active
#     CONFIG_SERVER_URL = "http://${module.cloudmap.service_names["config"]}.${module.cloudmap.namespace_name}:${var.config_port}"
#     EUREKA_HOST       = "${module.cloudmap.service_names["eureka"]}.${module.cloudmap.namespace_name}"
#     EUREKA_PORT       = var.eureka_port

#     PRODUCT_HOSTNAME = "${module.cloudmap.service_names["product"]}.${module.cloudmap.namespace_name}"
#     PRODUCT_PORT     = var.product_port

#     WRITE_POSTGRESQL_HOST     = module.rds.rds_primary.address
#     WRITE_POSTGRESQL_PORT     = var.rds_port
#     WRITE_DB_NAME             = var.rds_db_name
#     WRITE_POSTGRESQL_USERNAME = var.rds_username

#     READ_POSTGRESQL_HOST     = module.rds.rds_primary.address
#     READ_POSTGRESQL_PORT     = var.rds_port
#     READ_DB_NAME             = var.rds_db_name
#     READ_POSTGRESQL_USERNAME = var.rds_username

#     DATA_REDIS_HOST = module.elasticache.session_redis.primary_address
#     DATA_REDIS_PORT = 6379

#     CACHE_REDIS_HOST = module.elasticache.cache_redis.address
#     CACHE_REDIS_PORT = 6379

#     JWT_ACCESS_TOKEN_EXPIRATION_TIME  = var.jwt_access_expiration_time
#     JWT_REFRESH_TOKEN_EXPIRATION_TIME = var.jwt_refresh_expiration_time
#     JWT_ISSUER                        = var.jwt_issuer
#   }

#   ssm_parameters = {
#     JWT_ACCESS_TOKEN_SECRET   = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"]
#     JWT_REFRESH_TOKEN_SECRET  = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_REFRESH_TOKEN_SECRET"]
#     WRITE_POSTGRESQL_PASSWORD = module.ssm.parameter_arns["/${var.prefix}/rds/POSTGRESQL_PASSWORD"]
#     READ_POSTGRESQL_PASSWORD  = module.ssm.parameter_arns["/${var.prefix}/rds/POSTGRESQL_PASSWORD"]
#     DATA_REDIS_PASSWORD       = module.ssm.parameter_arns["/${var.prefix}/redis/DATA_REDIS_PASSWORD"]
#   }
# }

# module "ecs_order" {
#   source = "./modules/ecs-internal"

#   service_name = "${var.prefix}-order"
#   cluster_name = aws_ecs_cluster.come2us.name
#   region       = var.region

#   subnets            = module.network.private_subnet_ids
#   security_group_id  = module.sg.backend_sg_id
#   execution_role_arn = module.ecs_iam.task_execution_role_arn
#   task_role_arn      = module.ecs_iam.task_role_arn

#   ecr_image       = "${var.ecr_uri}-order"
#   image_tag_blue  = var.order_image_tag_blue
#   image_tag_green = var.order_image_tag_green
#   container_port  = var.order_port

#   active_color = var.order_active_color
#   warmup_color = var.order_warmup_color

#   service_discovery_arn = module.cloudmap.service_arns["order"]

#   environment = {
#     PROFILE_ACTIVE    = var.spring_profile_active
#     CONFIG_SERVER_URL = "http://${module.cloudmap.service_names["config"]}.${module.cloudmap.namespace_name}:${var.config_port}"
#     EUREKA_HOST       = "${module.cloudmap.service_names["eureka"]}.${module.cloudmap.namespace_name}"
#     EUREKA_PORT       = var.eureka_port

#     ORDER_HOSTNAME = "${module.cloudmap.service_names["order"]}.${module.cloudmap.namespace_name}"
#     ORDER_PORT     = var.order_port

#     WRITE_POSTGRESQL_HOST     = module.rds.rds_primary.address
#     WRITE_POSTGRESQL_PORT     = var.rds_port
#     WRITE_DB_NAME             = var.rds_db_name
#     WRITE_POSTGRESQL_USERNAME = var.rds_username

#     READ_POSTGRESQL_HOST     = module.rds.rds_primary.address
#     READ_POSTGRESQL_PORT     = var.rds_port
#     READ_DB_NAME             = var.rds_db_name
#     READ_POSTGRESQL_USERNAME = var.rds_username

#     DATA_REDIS_HOST = module.elasticache.session_redis.primary_address
#     DATA_REDIS_PORT = 6379

#     CACHE_REDIS_HOST = module.elasticache.cache_redis.address
#     CACHE_REDIS_PORT = 6379

#     JWT_ACCESS_TOKEN_EXPIRATION_TIME  = var.jwt_access_expiration_time
#     JWT_REFRESH_TOKEN_EXPIRATION_TIME = var.jwt_refresh_expiration_time
#     JWT_ISSUER                        = var.jwt_issuer
#   }

#   ssm_parameters = {
#     JWT_ACCESS_TOKEN_SECRET   = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_ACCESS_TOKEN_SECRET"]
#     JWT_REFRESH_TOKEN_SECRET  = module.ssm.parameter_arns["/${var.prefix}/jwt/JWT_REFRESH_TOKEN_SECRET"]
#     WRITE_POSTGRESQL_PASSWORD = module.ssm.parameter_arns["/${var.prefix}/rds/POSTGRESQL_PASSWORD"]
#     READ_POSTGRESQL_PASSWORD  = module.ssm.parameter_arns["/${var.prefix}/rds/POSTGRESQL_PASSWORD"]
#     DATA_REDIS_PASSWORD       = module.ssm.parameter_arns["/${var.prefix}/redis/DATA_REDIS_PASSWORD"]
#   }
# }

# module "route53" {
#   source = "./modules/route53"

#   domain_name = "come2us.store"

#   # service_alb_dns_name = module.alb_service.service_alb_dns
#   # service_alb_zone_id  = module.alb_service.alb_zone_id

#   jenkins_alb_dns_name = module.alb_jenkins.jenkins_alb_dns
#   jenkins_alb_zone_id  = module.alb_jenkins.alb_zone_id
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.9.0"

    name               = "${var.prefix}-eks"
    kubernetes_version = "1.30"

    vpc_id     = module.network.vpc_id
    subnet_ids = module.network.private_subnet_ids

    enable_cluster_creator_admin_permissions = true

    addons = {
        coredns                = {}
        kube-proxy             = {}
        eks-pod-identity-agent = {
            before_compute = true
            }
        vpc-cni                = {
            before_compute = true
            most_recent    = true
            }
    }

    eks_managed_node_groups = {
        default = {
            instance_types = ["t3.medium"]

            min_size       = 1
            max_size       = 3
            desired_size   = 2
        }
    }
    tags = {
        Project = "Come2us"
    }
}
