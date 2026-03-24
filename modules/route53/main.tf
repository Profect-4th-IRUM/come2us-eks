resource "aws_route53_zone" "main" {
  name = var.domain_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = {
    Name    = "${var.prefix}-wildcard-cert"
    Project = var.prefix
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  cert_validation_options = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options :
    dvo.resource_record_name => dvo...
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = local.cert_validation_options

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value[0].resource_record_name
  type    = each.value[0].resource_record_type
  records = [each.value[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
