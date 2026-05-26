#dev/backend

terraform {
  backend "s3" {
    bucket         = "tfstate-lionkdt5-team3"
    key            = "project2/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "tfstate-lock-team3"
    encrypt        = true
  }
}
