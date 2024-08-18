terraform {
  backend "s3" {
    bucket = "tf-state-vikshith" 
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}
