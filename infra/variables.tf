
# container port number

variable "container_port_number" {
  type        = number
  description = "port number the container listens on"
  default     = 8080

}

# domain name

variable "domain_name" {
  type        = string
  description = "Domain name for the ACM certificate and Route53 record"
  default     = "gatus.sakariyaaden.com"
}



# Project name

variable "project_name" {
  type        = string
  description = "Name of the project, used to build resource names and tags"
  default     = "ecs_project-gatus"


}

# desired count
variable "desired_count" {
  type        = number
  description = " number of tasks you want to run simultaneously"
  default     = 1

}

# cpu size
variable "cpu" {
  type        = string
  description = "cpu size of ecs task"
  default     = "256"

}

# memory size
variable "memory" {
  type        = string
  description = "memory size of ecs task"
  default     = "512"

}
