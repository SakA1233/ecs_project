# ACM certificate

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "${var.project_name}-acm-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}