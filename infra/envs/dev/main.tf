#dev/main.tf

module "vpc" {
  source = "../../modules/vpc"

  env          = "dev"
  cluster_name = "team3-dev-eks"
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "team3/foldy"
  # [리팩토링] dev 는 MUTABLE 유지(명시), prod 루트에서는 IMMUTABLE 로 넘길 것
  image_tag_mutability = "MUTABLE"
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
  # [리팩토링] bastion 모듈에 추가한 allowed_ssh_cidr 연결 (운영 시 회사/VPN IP 로 좁힐 것)
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

#S3
resource "aws_s3_bucket" "app_storage" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  # [리팩토링] Team 태그 제거 → provider default_tags 로 이동, Name 만 유지
  tags = {
    Name = var.s3_bucket_name
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
# [참고] aws_s3_bucket_cors_configuration 은 태그 미지원 리소스. 누락 아님

resource "aws_s3_bucket_public_access_block" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id

  # [리팩토링][보안] 버킷 정책에서 GetObject 만 public 으로 여는 것이 목적이므로
  # ACL 관련 차단은 켜두는 것이 안전. 정책 기반 공개는 아래 bucket_policy 로 충분
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}
# [참고] aws_s3_bucket_public_access_block 은 태그 미지원 리소스. 누락 아님

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
# [참고] aws_s3_bucket_policy 는 태그 미지원 리소스. 누락 아님
