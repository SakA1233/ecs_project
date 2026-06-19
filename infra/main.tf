module "vpc" {
  source = "./modules/vpc"
  project_name = var.project_name
}

module "sg" {
  source = "./modules/sg"
  project_name = var.project_name
  container_port_number = var.container_port_number
  vpc_id = module.vpc.vpc_id
  
}


module "ecr" {
  source = "./modules/ecr"
  project_name = var.project_name
  
}

module "alb" {
  source = "./modules/alb"
  project_name = var.project_name
  alb_sg_id = module.sg.alb_sg_id
  aws_subnet_ids = module.vpc.aws_subnet_ids
  container_port_number = var.container_port_number
  vpc_id = module.vpc.vpc_id
  
}

module "acm" {
  source = "./modules/acm"
  project_name = var.project_name
  domain_name = var.domain_name
  
}

module "route53" {
  source = "./modules/route53"
  project_name = var.project_name
  domain_name = var.domain_name
  acm_domain_validation_options = module.acm.acm_domain_validation_options
  acm_certificate_arn = module.acm.acm_certificate_arn
  alb_dns_name = module.alb.alb_dns_name
  alb_hosted_zone_id = module.alb.alb_hosted_zone_id
  
}


module "ecs" {
  source = "./modules/ecs"
  project_name = var.project_name
  container_port_number = var.container_port_number
  ecs_sg_id = module.sg.ecs_sg_id
  repository_url = module.ecr.repository_url
  target_group_arn = module.alb.target_group_arn
  aws_subnet_ids = module.vpc.aws_subnet_ids 
}



# Listeners for ALB http
resource "aws_lb_listener" "http_alb_listener" {
  load_balancer_arn = module.alb.alb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
  type = "redirect"

  redirect {
    port        = "443"
    protocol    = "HTTPS"
    status_code = "HTTP_301"
  }
}
}



# HTTPS listener alb

resource "aws_lb_listener" "https_alb_listener" {
  load_balancer_arn = module.alb.alb_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = module.acm.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arn
  }
}

