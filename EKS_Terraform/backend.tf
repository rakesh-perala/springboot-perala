terraform {
  backend "s3" {
    bucket = "sen-dev34343" # Replace with your actual S3 bucket name
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
  }
}
