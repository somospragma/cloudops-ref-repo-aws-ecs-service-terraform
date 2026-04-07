terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "principal"
  
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.environment
      Project     = var.project
      Client      = var.client
    }
  }
}
