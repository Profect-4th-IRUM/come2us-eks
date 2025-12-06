output "name_servers" {
  description = "The name servers assigned by Route53"
  value       = aws_route53_zone.main.name_servers
}
output "zone_id" {
  description = "The ID of the Route53 hosted zone"
  value       = aws_route53_zone.main.zone_id
}
