# domain name

variable "domain_name" {
  type        = string
  description = "Domain name for the ACM certificate and Route53 record"
}



# Project name

variable "project_name" {
    type = string
    description = "Name of the project, used to build resource names and tags"
  
}


# acm domian validation options

variable "acm_domain_validation_options" {
    type = any
    description = "domain valdation options for acm"
  
}


# acm cert arn

variable "acm_certificate_arn" {
    type = string
    description = "arn of acm cert"
  
}

variable "alb_dns_name" {
    type = string
    description = "alb dns name"
  
}

variable "alb_hosted_zone_id" {
    type = string
    description = "zone id for alb hosted zone"
  
}