terraform {
  backend "s3" {
    bucket         = "glg-state-bucket-test-s2r4-main"
    dynamodb_table = "glg-state-bucket-test-s2r4-locks"
    key            = "aws/prototype/test"
    region         = "us-east-1"
    encrypt        = true
    max_retries    = 2
  }
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.27"
    }
  }
}

provider "aws" {
  max_retries         = 2 # default:25
  region              = "us-east-1"
  allowed_account_ids = ["988857891049"]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
locals {
  aws = {
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
    dns_suffix = data.aws_partition.current.dns_suffix
    partition  = data.aws_partition.current.partition
  }
}

output "aws" {
  value = local.aws
}

resource "time_sleep" "wait" {
  create_duration  = "10s"
  destroy_duration = "10s"
}
