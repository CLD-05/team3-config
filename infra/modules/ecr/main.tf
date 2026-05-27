#ecr/main.tf

# ECR Repository 생성
resource "aws_ecr_repository" "this" {
  name = var.repository_name
  ### MUTABLE은 같은 태그로 이미지 덮어쓰기가 가능해 롤백 추적이 어려워집니다.
  ### prod 환경 전환 시 IMMUTABLE로 변경하세요.
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    ### 보안 요구사항이 높아지면 KMS로 전환하세요.
    encryption_type = "AES256"
  }
}

# IAM용 Repository 생성
resource "aws_ecr_repository" "iam" {
  name = "${var.repository_name}-iam"
  ### prod 환경 전환 시 IMMUTABLE로 변경하세요.
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    ### 보안 요구사항이 높아지면 KMS로 전환하세요.
    encryption_type = "AES256"
  }
}

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
