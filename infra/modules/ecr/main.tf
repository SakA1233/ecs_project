#  Create ECR Repo

resource "aws_ecr_repository" "gatus" {
  name                 = "ecs_project-gatus"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}