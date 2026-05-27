#iam.outputs.tf✅

# GitHub Actions 관련 아웃풋

output "github_actions_role_arn" {
  description = "GitHub Actions 워크플로우(.github/workflows/*.yml)의 'role-to-assume'에 주입할 IAM Role ARN"
  value       = aws_iam_role.github_actions_ecr_role.arn
}

output "app_irsa_role_arn" {
  value       = aws_iam_role.app_irsa_role.arn
  description = "The ARN of the IAM Role to be annotated on the Kubernetes ServiceAccount (eks.amazonaws.com/role-arn)"
}

output "alb_controller_irsa_role_arn" {
  description = "ALB Controller IRSA Role ARN (Helm 설치 시 주입)"
  value       = aws_iam_role.alb_controller_irsa_role.arn
}
