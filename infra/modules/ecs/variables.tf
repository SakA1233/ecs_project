# Project name

variable "project_name" {
  type        = string
  description = "Name of the project, used to build resource names and tags"

}



# container port number

variable "container_port_number" {
  type        = number
  description = "port number the container listens on"

}


variable "repository_url" {
  type        = string
  description = "url for ecr repo"

}

variable "aws_subnet_ids" {
  type        = list(string)
  description = "subnet ids"

}

variable "ecs_sg_id" {
  type        = string
  description = "ecs sg id"

}

variable "target_group_arn" {
  type        = string
  description = "alb target group arn"

}


variable "desired_count" {
  type        = number
  description = " number of tasks you want to run simultaneously"
}

variable "cpu" {
  type        = string
  description = "cpu size of ecs task"
}

variable "memory" {
  type        = string
  description = "memory size of ecs task"
}
