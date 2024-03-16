provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region = var.AWS_REGION

assume_role {
  #the role ARN within Account A to assume role into. Created in step 1
  role_arn = "arn:aws:iam::533267419089:role/Engineer"

  }
}
