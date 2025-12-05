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

output "karpenter_controller_role_name" {
  value = module.karpenter.iam_role_name
}

output "karpenter_controller_role_arn" {
  value = module.karpenter.iam_role_arn
}
