output "cluster_name" {
  description = "생성된 EKS 클러스터 이름"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API 서버 엔드포인트 URL (kubectl/HTTP 클라이언트가 접근할 주소)"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "kubeconfig 생성 시 사용할 클러스터 CA 인증서"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL (IRSA 신뢰 관계 설정에 사용)"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_name" {
  description = "생성된 EKS 워커 노드 그룹 이름"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  description = "워커 노드가 사용하는 IAM Role ARN"
  value       = aws_iam_role.eks_node.arn
}

output "oidc_provider_arn" {
  description = "EKS OIDC Provider ARN (IRSA Role의 Principal로 사용)"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "EKS OIDC Provider URL (https:// 제외)"
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}

output "node_security_group_id" {
  description = "EKS 클러스터 보안 그룹 ID (RDS 등 다른 리소스에서 ingress 소스로 사용)"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
