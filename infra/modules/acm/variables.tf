# Project name

variable "project_name" {
    type = string
    description = "Name of the project, used to build resource names and tags"

  
}


# domain name

variable "domain_name" {
  type        = string
  description = "Domain name for the ACM certificate and Route53 record"
}