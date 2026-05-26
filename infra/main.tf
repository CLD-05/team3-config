module "ecr" {
  source = "./modules/ecr"
  # 현재는 테스트용 repository 사용 중
  # 추후 실제 서비스 이름으로 변경 필요
  #
  # 권장 패턴:
  # team-x/app-name
  repository_name = "test-app"
}
