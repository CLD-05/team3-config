#prod/outputs.tf

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS 클러스터 API 엔드포인트"
  value       = module.eks.cluster_endpoint
}

# [리팩토링] 위에서 ecr 모듈을 추가했으므로 주석 해제
output "ecr_repository_url" {
  description = "ECR 리포지토리 URL (CI에서 이미지 push 시 사용)"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS 엔드포인트 (K8s Secret 주입용)"
  value       = module.rds.endpoint
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Role ARN (워크플로우 role-to-assume에 주입)"
  value       = module.iam.github_actions_role_arn
}

output "app_irsa_role_arn" {
  description = "App Pod IRSA Role ARN (ServiceAccount annotation에 주입)"
  value       = module.iam.app_irsa_role_arn
}

output "rds_db_name" {
  description = "RDS 데이터베이스 이름 (K8s Secret 주입용)"
  value       = module.rds.db_name
}

output "rds_db_username" {
  description = "RDS 마스터 계정 이름 (K8s Secret 주입용)"
  value       = module.rds.db_username
}

output "alb_controller_irsa_role_arn" {
  description = "AWS Load Balancer Controller IRSA Role ARN"
  value       = module.iam.alb_controller_irsa_role_arn
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}
