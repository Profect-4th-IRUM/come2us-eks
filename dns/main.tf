terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
  }

  backend "s3" {}
}

module "route53" {
  source      = "../modules/route53"
  domain_name = var.domain_name
  prefix      = var.prefix
}
