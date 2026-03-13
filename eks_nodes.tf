locals {
  eks_managed_node_groups = {
    infra_ng = {
      min_size     = 2
      max_size     = 6
      desired_size = 3

      instance_types = ["t3.large"]
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND"

      labels = {
        node_type                 = "infra"
        capacity                  = "on_demand"
        "karpenter.sh/controller" = "true"
      }

      tags = {
        Name = "come2us-infra-node"
      }

      taints = [
        {
          key    = "node_type"
          value  = "infra"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    app_ng = {
      min_size     = 2
      max_size     = 5
      desired_size = 2

      instance_types = ["t3.medium"] # or t3.small
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND"

      labels = {
        node_type = "app"
        capacity  = "on_demand"
      }

      tags = {
        Name = "come2us-app-node"
      }
    }
  }
}