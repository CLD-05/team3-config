# GitHub Actions 관련 아웃풋

output "github_actions_role_arn" {
  description = "GitHub Actions 워크플로우(.github/workflows/*.yml)의 'role-to-assume'에 주입할 IAM Role ARN"
  value       = aws_iam_role.github_actions_ecr_role.arn
}
