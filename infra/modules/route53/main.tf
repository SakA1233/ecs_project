# Route 53 hosted zones

resource "aws_route53_zone" "gatus" {
  name = var.domain_name

  tags = {
    Name = "${var.project_name}-hosted-zone"
  }
}


# Route 53 record
resource "aws_route53_record" "gatus" {
  for_each = {
    for dvo in var.acm_domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.gatus.zone_id
}



# ACM validation
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = var.acm_certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.gatus : record.fqdn]
}



# Route 53 record alb pointer

resource "aws_route53_record" "gatus_alb_pointer" {
  zone_id = aws_route53_zone.gatus.id
  name    = var.domain_name
  type    = "A"
   alias {
    name                   = var.alb_dns_name # ALB DNS name
    zone_id                = var.alb_hosted_zone_id # ALB hosted zone ID
    evaluate_target_health = true
  }
}