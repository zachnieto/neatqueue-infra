terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket         = "neatqueue-terraform-state"
    key            = "ecs/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "neatqueue-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}


