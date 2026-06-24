terraform {
  backend "s3" {
    bucket         = "aws-with-roshan"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-github"
    encrypt        = true
  }
}
