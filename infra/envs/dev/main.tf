#dev/main.tf

module "vpc" {
  source = "../../modules/vpc"

  env          = "dev"
  cluster_name = "team3-dev-eks"
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "team3/foldy"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "team3-dev-eks"
  cluster_version    = "1.35"
  private_subnet_ids = module.vpc.private_subnet_ids

  admin_user_arns = var.admin_user_arns
  github_actions_role_arns = {
    github_actions = module.iam.github_actions_role_arn
  }

  #bastion
  bastion_sg_id = module.bastion.bastion_sg_id
}

module "rds" {
  source = "../../modules/rds"

  vpc_id                = module.vpc.vpc_id
  rds_subnet_group_name = module.vpc.rds_subnet_group_name
  eks_sg_id             = module.eks.node_security_group_id
  bastion_sg_id         = module.bastion.bastion_sg_id
  db_password           = var.db_password
  env                   = "dev"
  db_username           = var.db_username
  rds_delete_protect    = var.rds_delete_protect
  multi_az              = var.rds_multi_az
}

## iam/variables.tf 를 해결한 후 이곳의 주석을 해제
module "iam" {
  source = "../../modules/iam"

  env                      = "dev"
  ecr_repository_arn       = module.ecr.repository_arn
  eks_oidc_provider_arn    = module.eks.oidc_provider_arn
  k8s_namespace            = "app"
  k8s_service_account_name = "app-sa"
  s3_bucket_name           = var.s3_bucket_name
}

#bastion
module "bastion" {
  source = "../../modules/bastion"

  env              = "dev"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  key_pair_name    = var.key_pair_name
}

#S3
resource "aws_s3_bucket" "app_storage" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name = var.s3_bucket_name
    Team = "team3"
  }
}

resource "aws_s3_bucket_cors_configuration" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "app_storage" {
  bucket     = aws_s3_bucket.app_storage.id
  depends_on = [aws_s3_bucket_public_access_block.app_storage]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.app_storage.arn}/*"
    }]
  })
}
