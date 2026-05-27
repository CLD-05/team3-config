#dev/outputs.tf

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

#bastion
output "bastion_public_ip" {
  description = "Bastion 퍼블릭 IP (SSH 접속용)"
  value       = module.bastion.bastion_public_ip
}
