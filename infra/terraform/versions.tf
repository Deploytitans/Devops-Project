terraform {
  required_version = ">= 1.8.0"

  # Supply bucket, key, region, and use_lockfile=true with -backend-config.
  # State infrastructure must be created separately so application teardown
  # cannot destroy its own state or lock.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
