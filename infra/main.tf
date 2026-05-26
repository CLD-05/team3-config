# 1. 네트워크 구축
module "vpc" {
  source = "./modules/vpc" # VPC 코드가 있는 경로
}

# 2. RDS 구축 (VPC 아웃풋을 그대로 인자로 주입)
module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id

  # 방금 추가한 VPC의 아웃풋을 RDS 모듈의 입력 변수로 쏙 넣어줍니다.
  db_subnet_ids = module.vpc.db_subnet_ids

  rds_subnet_group_name = module.vpc.rds_subnet_group_name
  db_password           = var.db_password
  eks_sg_id             = module.eks.node_security_group_id
}
