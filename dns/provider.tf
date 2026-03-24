provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  assume_role {
    role_arn = var.terraform_role_arn
  }
}
