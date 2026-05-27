#eks/access.tf

# ───────────────────────────────────────
# aws-auth ConfigMap으로 팀원 권한 부여
# ConfigMap 모드에서는 Access Entry 사용 불가
# ───────────────────────────────────────
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      for arn in var.admin_user_arns : {
        userarn  = arn
        username = split("/", arn)[1]
        groups   = ["system:masters"]
      }
    ])
  }

  force = true
}

# ───────────────────────────────────────
# GitHub Actions Role → 클러스터 admin 권한 (CD용)
# ───────────────────────────────────────
### ArgoCD 및 GitHub Actions OIDC Role 구성 완료 후 주석을 해제하세요.
### 지금 해제하면 iam 모듈과 순환참조가 발생합니다.
### 해제 순서: 1) iam 모듈 apply 완료 → 2) role ARN 확인 → 3) 주석 해제 후 재apply
# resource "aws_eks_access_entry" "github_actions" {
#   for_each = var.github_actions_role_arns

#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = each.value
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "github_actions" {
#   for_each = var.github_actions_role_arns

#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = each.value
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

#   access_scope {
#     type       = "namespace"
#     namespaces = ["app"]
#   }

#   depends_on = [aws_eks_access_entry.github_actions]
# }
