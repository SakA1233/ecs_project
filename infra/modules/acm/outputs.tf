# acm cert arn

output "acm_certificate_arn" {
    value = aws_acm_certificate.cert.arn
  
}


output "acm_domain_validation_options" {
  
  value = aws_acm_certificate.cert.domain_validation_options
}