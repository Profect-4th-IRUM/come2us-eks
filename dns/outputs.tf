output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.zone_id
}

output "name_servers" {
  description = "Route53 name servers"
  value       = module.route53.name_servers
}

output "acm_certificate_arn" {
  description = "Wildcard ACM certificate ARN"
  value       = module.route53.acm_certificate_arn
}
