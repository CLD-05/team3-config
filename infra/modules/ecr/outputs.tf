#ecr/outputs.tf

output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.this.repository_url
}

### IAM 모듈에서 ECR 접근 정책 작성 시 ARN이 필요합니다. 아래 output을 추가하세요.
output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.this.arn
}
