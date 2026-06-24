terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.40.0"
    }
  }
}


provider "aws" {
  #configuration opitions
  region = var.aws_region # specify the AWS region to use
}
