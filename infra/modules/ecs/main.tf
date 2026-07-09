# Create ECS Cluster

resource "aws_ecs_cluster" "ecs_project_gatus" {
  name = "ecs_project-gatus"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

# IAM Execution role
resource "aws_iam_role" "ecs_execution" {
  name = "gatus-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
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

# ECS Task definition

resource "aws_ecs_task_definition" "ecs_project_gatus" {
  family                   = "ecs_project-gatus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${var.repository_url}:v1.0.1"
    essential = true

    portMappings = [{
      containerPort = var.container_port_number
      protocol      = "tcp"
    }]


    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = data.aws_region.current_region.region
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
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_sg_id]
    subnets          = var.aws_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port_number
  }

}

