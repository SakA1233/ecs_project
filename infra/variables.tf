# VPC Variables

variable "vpc_cidr_block" {
    type = string
    description = "cidr block for the vpc"
    default = "10.0.0.0/22"
  
}

variable "public_subnet_count" {
    type = number
    description = "number of public subnets to create"
    default = 2
  
}

variable "subnet_newbits" {
  type        = number
  description = "Number of additional bits for subnet CIDR calculation"
  default     = 3
}

# container port number

variable "container_port_number" {
    type = number
    description = "port number the container listens on"
    default = 8080
  
}

# domain name

variable "domain_name" {
  type        = string
  description = "Domain name for the ACM certificate and Route53 record"
  default     = "gatus.sakariyaaden.com"
}



# Project name

variable "project_name" {
    type = string
    description = "Name of the project, used to build resource names and tags"
    default = "ecs_project-gatus"

  
}

