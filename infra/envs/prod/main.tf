#prod/main.tf

module "vpc" {
  source = "../../modules/vpc"

  env          = "prod"
  cluster_name = "team3-prod-eks"
}

# [import] dev 에서 소유권 이전받을 ECR. 실제 리소스가 MUTABLE 이므로 우선 MUTABLE.
# import + plan 깨끗한 거 확인 후 IMMUTABLE 로 변경 예정
module "ecr" {
  source = "../../modules/ecr"

  repository_name      = "team3/foldy"
  image_tag_mutability = "MUTABLE"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "team3-prod-eks"
  cluster_version    = "1.35"
  private_subnet_ids = module.vpc.private_subnet_ids

  node_desired_size = 2
  node_min_size     = 2
  node_max_size     = 4

  endpoint_public_access = true

  admin_user_arns = var.admin_user_arns
  github_actions_role_arns = {
    github_actions = module.iam.github_actions_role_arn
  }
  bastion_sg_id = module.bastion.bastion_sg_id
}

module "rds" {
  source = "../../modules/rds"

  vpc_id                      = module.vpc.vpc_id
  rds_subnet_group_name       = module.vpc.rds_subnet_group_name
  eks_sg_id                   = module.eks.node_security_group_id
  bastion_sg_id               = module.bastion.bastion_sg_id
  db_password                 = var.db_password
  db_username                 = var.db_username
  env                         = "prod"
  rds_delete_protect          = var.rds_delete_protect
  multi_az                    = var.rds_multi_az
  rds_backup_retention_period = var.rds_backup_retention_period
  # [import] 기존 RDS 이름 유지 (변경 시 재부팅/엔드포인트 변경 위험)
  db_identifier = "prod-foldy-db-server"
}

module "iam" {
  source = "../../modules/iam"

  env                      = "prod"
  ecr_repository_arn       = module.ecr.repository_arn
  eks_oidc_provider_arn    = module.eks.oidc_provider_arn
  k8s_namespace            = "app"
  k8s_service_account_name = "app-sa"
  s3_bucket_name           = var.s3_bucket_name
}

module "bastion" {
  source = "../../modules/bastion"

  env              = "prod"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  key_pair_name    = var.key_pair_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# ─────────────────────────────────────────────────────────────────
# S3 (dev 에서 소유권 이전받음) — import 대상
# import 단계에선 실제값에 맞춤. 보안 강화는 import 완료 후 별도로.
# ─────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "app_storage" {
  bucket        = var.s3_bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name = var.s3_bucket_name
  }
}

# [import] 버저닝 — 방금 활성화했으므로 코드에도 반영
resource "aws_s3_bucket_versioning" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
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

  # [import] 실제 dev 설정이 전부 false 였음. import 깨끗하게 하려고 실제값에 맞춤.
  # 보안 강화(true)는 import 완료 후 별도 커밋으로.
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
