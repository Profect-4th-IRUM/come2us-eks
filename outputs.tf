# output "jenkins_alb_dns" { value = module.alb_jenkins.jenkins_alb_dns }
# output "jenkins_private_ip" { value = module.jenkins.private_ip }

# output "bastion_public_ip" {
#   value = module.bastion.public_ip
# }

# output "bastion_ssh" {
#   value = module.bastion.ssh_command
# }

output "route53_ns" {
  value = module.route53.name_servers
}

output "acm_certificate_arn" {
  value = module.route53.acm_certificate_arn
}

# Karpenter
output "karpenter_controller_role_name" {
  value = module.karpenter.iam_role_name
}

output "karpenter_controller_role_arn" {
  value = module.karpenter.iam_role_arn
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "karpenter_node_role_arn" {
  value = module.karpenter.node_iam_role_arn
}

# ALB Controller
output "alb_controller_irsa_role_arn" {
  value = module.alb_controller_irsa.iam_role_arn # ServiceAccount annotation에 필요
}

# EKS Cluster
output "cluster_name" {
  value = module.eks.cluster_name # Karpenter, ArgoCD 설정에 필요
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint # Karpenter Helm values에 필요
}
