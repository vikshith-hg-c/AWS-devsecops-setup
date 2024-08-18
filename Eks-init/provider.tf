terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  alias      = "ap-south-1"
  region     = "ap-south-1"
  access_key = "AKIAUY4SACTXJW4TK3ST"
  secret_key = "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"
}
