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
  region = "eu-west-2" # specify the AWS region to use
}
