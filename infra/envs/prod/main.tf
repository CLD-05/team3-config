#prod/main.tf

module "vpc" {
  source = "../../modules/vpc"

  env          = "prod"
  cluster_name = "team3-prod-eks"
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "team3/foldy"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "team3-prod-eks"
  cluster_version    = "1.35"
  private_subnet_ids = module.vpc.private_subnet_ids

  node_desired_size = 2
  node_min_size     = 2
  node_max_size     = 4

  admin_user_arns = var.admin_user_arns
  github_actions_role_arns = {
    github_actions = module.iam.github_actions_role_arn
  }
  bastion_sg_id = module.bastion.bastion_sg_id
}

module "rds" {
  source = "../../modules/rds"

  vpc_id                = module.vpc.vpc_id
  rds_subnet_group_name = module.vpc.rds_subnet_group_name
  eks_sg_id             = module.eks.node_security_group_id
  db_password           = var.db_password
  db_username           = var.db_username
  env                   = "prod"
  # multi_az              = true
  # deletion_protection   = true
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

# prod는 Multi-AZ를 활성화해 장애 시 자동 페일오버를 지원합니다.
# hint: rds/variables.tf에 multi_az 변수를 추가하고
#       aws_db_instance.mysql의 multi_az 속성에 연결하세요.
# hint: prod는 deletion_protection = true로 변경하세요.
# hint: instance_class를 db.t3.small 이상으로 올리는 것을 권장합니다.
# multi_az            = true
# deletion_protection = true

# module "iam" {
#   source = "../../modules/iam"

#   env                      = "prod"
#   ecr_repository_arn       = module.ecr.repository_arn
#   eks_oidc_provider_arn    = module.eks.oidc_provider_arn
#   k8s_namespace            = "app"
#   k8s_service_account_name = "app-sa"
#   s3_bucket_name           = var.s3_bucket_name
# }


# prod 코드가 동작하려면 아래 모듈 수정이 선행되어야 합니다.

# rds/variables.tf
#   hint: multi_az 변수 추가 (type = bool, default = false)
#   hint: deletion_protection 변수 추가 (type = bool, default = false)

# rds/main.tf
#   hint: aws_db_instance.mysql에 multi_az = var.multi_az 연결
#   hint: aws_db_instance.mysql에 deletion_protection = var.deletion_protection 연결

# vpc/main.tf
#   hint: prod는 NAT Gateway를 2a, 2c 각각 1개씩 총 2개 배치해야
#         2c 프라이빗 서브넷의 아웃바운드가 2a NAT를 타지 않습니다.
#   hint: aws_nat_gateway.nat_gw_c, aws_eip.nat_c 리소스를 추가하고
#         private_c 서브넷용 라우트 테이블을 분리하세요.

# vpc/variables.tf
#   hint: env 변수의 default를 제거하고 envs/dev, envs/prod에서 명시적으로 넘기세요.
