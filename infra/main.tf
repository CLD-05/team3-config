# 1. 네트워크 구축
module "vpc" {
  source = "./modules/vpc" # VPC 코드가 있는 경로
}

# 2. RDS 구축 (VPC 아웃풋을 그대로 인자로 주입)
module "rds" {
  source = "./modules/rds"

  vpc_id                = module.vpc.vpc_id
  rds_subnet_group_name = module.vpc.rds_subnet_group_name # VPC 아웃풋 이름을 주입!
  db_password           = var.db_password
  eks_sg_id             = module.eks.node_security_group_id
}

module "ecr" {
  source = "./modules/ecr"
  # ... 생략
}

module "iam" {
  source = "./modules/iam"

  ecr_repository_url = module.ecr.repository_url
  #..
}
