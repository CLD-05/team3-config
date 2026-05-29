#ecr/outputs.tf

output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.this.arn
}

# [리팩토링] 주석 처리된 IAM repository output 삭제
