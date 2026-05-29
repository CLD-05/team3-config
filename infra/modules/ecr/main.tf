#ecr/main.tf

# ECR Repository 생성
resource "aws_ecr_repository" "this" {
  name = var.repository_name
  ### MUTABLE은 같은 태그로 이미지 덮어쓰기가 가능해 롤백 추적이 어려워집니다.
  ### prod 환경 전환 시 IMMUTABLE로 변경하세요.
  # [리팩토링] 환경별로 제어 가능하도록 변수화 (prod 자동 IMMUTABLE)
  image_tag_mutability = var.image_tag_mutability

  # 이미지 있어도 terraform destroy 시 강제 삭제
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    ### 보안 요구사항이 높아지면 KMS로 전환하세요.
    encryption_type = "AES256"
  }
  # [리팩토링] Team 태그 제거 → provider default_tags 로 이동, Name 만 유지
  tags = {
    Name = "team3-${var.repository_name}"
  }
}

# [리팩토링] 주석 처리된 IAM repository 죽은 코드 삭제

# ECR Lifecycle Policy 설정
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "untagged 이미지 1일 후 자동 삭제"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "최근 10개 이미지만 유지"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
# [참고] aws_ecr_lifecycle_policy 는 태그 미지원 리소스. 태그 누락 아님
