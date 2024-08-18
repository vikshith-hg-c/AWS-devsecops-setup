terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "access_key" {}
variable "secret_key" {}

# Configure the AWS Provider
provider "aws" {
  alias      = "ap-south-1"
  region     = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}