data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "come2us-prod-tfstate"
    key    = "dns/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
