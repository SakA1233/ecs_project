# Create s3 bucket
resource "aws_s3_bucket" "state_s3_bucket" {
  bucket = "ecs-project-gatus-state-s3-bucket"

  tags = {
    Name = "ecs-project-gatus-state-s3-bucket"
  }
}

# enable versioning
resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.state_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#enable access controls
resource "aws_s3_bucket_public_access_block" "state_s3_bucket_access" {
  bucket = aws_s3_bucket.state_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# create oidc

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name    = "github-actions-oidc"
    Purpose = "CI/CD pipeline authentication"
  }
}




# IAM roles and policy

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Lock this down to your specific repo and branches
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.allowed_subjects
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Name    = var.role_name
    Purpose = "GitHub Actions CI/CD for ECS"
  }
}


resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
