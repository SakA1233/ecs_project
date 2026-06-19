# create ALB
resource "aws_lb" "alb" {
  name               = "ecs-project-gatus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.aws_subnet_ids
  enable_deletion_protection = false


  tags = {
    Name = "${var.project_name}-alb"
  }
}


# ALB Target Group

resource "aws_lb_target_group" "alb" {
  name        = "ecs-project-gatus-target-group"
  target_type = "ip"
  port        = var.container_port_number
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
  path    = "/health"
  matcher = "200"
}

tags = {
  Name = "${var.project_name}-target-group"
}
}


