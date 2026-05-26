module "ecr" {
  source = "./modules/ecr"
  # 현재는 테스트용 repository 사용 중
  # 추후 실제 서비스 이름으로 변경 필요
  #
  # 권장 패턴:
  # team-x/app-name
  repository_name = "test-app"
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = "team3-dev-eks"
  cluster_version = "1.29"
  # TODO:
  # VPC 모듈 연결 전 임시 subnet placeholder 사용
  # 추후 module.vpc.private_subnet_ids 로 변경 예정
  private_subnet_ids = [
    "subnet-placeholder-a",
    "subnet-placeholder-c"
  ]
}
