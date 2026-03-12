terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-2"

  default_tags {
    tags = {
      Project = "DevOps-EKS"
      Owner   = "DevOpsFactory"
    }
  }
}
