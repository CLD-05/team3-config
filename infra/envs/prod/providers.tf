provider "aws" {
  region = "ap-northeast-2"

  # 공통 태그 설정
  # 리소스 식별 및 비용 추적 용도
  default_tags {
    tags = {
      Team        = "team3"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
