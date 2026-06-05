
# Create Vpc
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/22"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Custom_VPC"
  }

}

# List az available
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Public subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.custom_vpc.cidr_block, 3, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "public-${count.index + 1}"
    Type = "public"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "my-app-igw"
  }
}

# Create Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate subnets with route tables
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ALB Security Group - accepts traffic from internet
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}


# ECS Security Group - ONLY accepts traffic from ALB
resource "aws_security_group" "ecs" {
  name        = "ecs-tasks-sg"
  description = "ECS tasks security group"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description     = "Traffic from ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Reference SG, not CIDR!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecs-tasks-sg" }
}


#  Create ECR Repo

resource "aws_ecr_repository" "gatus" {
  name                 = "ecs_project-gatus"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "ecs_project-gatus"
  }
}

# create ALB
resource "aws_lb" "alb" {
  name               = "ecs-project-gatus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  enable_deletion_protection = false


  tags = {
    Name = "ecs-project-gatus-alb"
  }
}

# Create ECS Cluster

resource "aws_ecs_cluster" "ecs_project_gatus" {
  name = "ecs_project-gatus"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ecs_project-gatus"
  }
}


# ALB Target Group

resource "aws_lb_target_group" "alb" {
  name        = "ecs-project-gatus-target-group"
  target_type = "ip"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.custom_vpc.id

  health_check {
  path    = "/health"
  matcher = "200"
}

tags = {
  Name = "ecs-project-gatus-target-group"
}
}

# Listeners for ALB
resource "aws_lb_listener" "http_alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
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


# ACM certificate

resource "aws_acm_certificate" "cert" {
  domain_name       = "gatus.sakariyaaden.com"
  validation_method = "DNS"

  tags = {
    Name = "ecs_project-gatus-acm-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Route 53 hosted zones

resource "aws_route53_zone" "gatus" {
  name = "gatus.sakariyaaden.com"

  tags = {
    Name = "gatus.sakariyaaden.com"
  }
}


# Route 53 record
resource "aws_route53_record" "gatus" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.gatus.zone_id
}


# ACM validation
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.gatus : record.fqdn]
}



# HTTPS listener alb

resource "aws_lb_listener" "https_alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

# IAM Execution role
resource "aws_iam_role" "ecs_execution" {
  name = "gatus-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# IAM execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# cloudwatch log
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/gatus"
}

# ECS Task defintion

resource "aws_ecs_task_definition" "ecs_project_gatus" {
  family                   = "ecs_project-gatus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.gatus.repository_url}:v1.0.1"
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = "eu-west-2"
        "awslogs-stream-prefix" = "ecs"
      }
    }

  }])
}


# ECS service

resource "aws_ecs_service" "main" {
    name            = "ecs_project-gatus"
    cluster         = aws_ecs_cluster.ecs_project_gatus.id
    task_definition = aws_ecs_task_definition.ecs_project_gatus.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
        security_groups  = [aws_security_group.ecs.id]
        subnets          = aws_subnet.public[*].id
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.alb.arn
        container_name   = "app"
        container_port   = 8080
    }

    depends_on = [aws_lb_listener.http_alb_listener, aws_lb_listener.https_alb_listener, aws_iam_role_policy_attachment.ecs_execution]
}


# Route 53 record

resource "aws_route53_record" "gatus_alb_pointer" {
  zone_id = aws_route53_zone.gatus.id
  name    = "gatus.sakariyaaden.com"
  type    = "A"
   alias {
    name                   = aws_lb.alb.dns_name # ALB DNS name
    zone_id                = aws_lb.alb.zone_id # ALB hosted zone ID
    evaluate_target_health = true
  }
}