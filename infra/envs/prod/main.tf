module "vpc" {
  source = "../../modules/vpc"
}

module "ecr" {
  source          = "../../modules/ecr"
  repository_name = "team3/team3-app"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "team3-prod-eks"
  cluster_version    = "1.30"
  private_subnet_ids = module.vpc.private_subnet_ids

  node_desired_size = 2
  node_min_size     = 2
  node_max_size     = 4

  #admin_user_arns = var.admin_user_arns
  github_actions_role_arn = module.iam.github_actions_role_arn
}

module "rds" {
  source = "../../modules/rds"

  vpc_id                = module.vpc.vpc_id
  rds_subnet_group_name = module.vpc.rds_subnet_group_name
  eks_sg_id             = module.eks.node_security_group_id
  db_password           = var.db_password
}

module "iam" {
  source = "../../modules/iam"

  env                      = "prod"
  ecr_repository_url       = module.ecr.repository_url
  eks_oidc_provider_arn    = module.eks.oidc_provider_arn
  k8s_namespace            = "app"
  k8s_service_account_name = "app-sa"
  s3_bucket_name           = var.s3_bucket_name
}
