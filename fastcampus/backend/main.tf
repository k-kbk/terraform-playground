terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }

  # backend "local" {}

  backend "s3" {
    bucket       = "demo-terraform-backend20250808052355533700000001"
    key          = "demo-terraform-state"
    region       = "ap-northeast-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket_prefix = "demo-terraform-backend"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "demo_versioning" {
  bucket = aws_s3_bucket.demo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
