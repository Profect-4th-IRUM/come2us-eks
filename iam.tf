module "iam" {
  source        = "./modules/eks-iam"
  cluster_name  = module.eks.cluster_name
  account_id    = var.account_id
  eks_admin_user = var.eks_admin_user
  terraform_role_arn = var.terraform_role_arn
}

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${var.prefix}-alb-controller-irsa"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}
