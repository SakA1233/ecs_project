# container port number

variable "container_port_number" {
    type = number
    description = "port number the container listens on"
  
}


# Project name

variable "project_name" {
    type = string
    description = "Name of the project, used to build resource names and tags"

}

# vpc id

variable "vpc_id" {
    type = string
    description = "vpc id to attach to security groups"
  
}

