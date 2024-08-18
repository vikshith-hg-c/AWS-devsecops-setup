terraform {
  backend "s3" {
    bucket = "tf-state-vikshith" # Replace with your actual S3 bucket name
    key    = "Devops/terraform.tfstate"
    region = "ap-south-1"
  }
}
