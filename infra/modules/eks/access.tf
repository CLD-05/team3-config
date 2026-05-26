#eks/access.tf

# ───────────────────────────────────────
# 팀원 IAM User → 클러스터 admin 권한
# ───────────────────────────────────────
resource "aws_eks_access_entry" "admin_users" {
  for_each = toset(var.admin_user_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_users" {
  for_each = toset(var.admin_user_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_users]
}

# ───────────────────────────────────────
# GitHub Actions Role → 클러스터 admin 권한 (CD용)
# ───────────────────────────────────────
### ArgoCD 및 GitHub Actions OIDC Role 구성 완료 후 주석을 해제하세요.
### 지금 해제하면 iam 모듈과 순환참조가 발생합니다.
### 해제 순서: 1) iam 모듈 apply 완료 → 2) role ARN 확인 → 3) 주석 해제 후 재apply
# resource "aws_eks_access_entry" "github_actions" {
#   count = var.github_actions_role_arn != "" ? 1 : 0

#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = var.github_actions_role_arn
#   type          = "STANDARD"

#   lifecycle {
#     precondition {
#       condition     = var.github_actions_role_arn != ""
#       error_message = "github_actions_role_arn must not be empty"
#     }
#   }
# }

# resource "aws_eks_access_policy_association" "github_actions" {
#   count = var.github_actions_role_arn != "" ? 1 : 0

#   cluster_name  = aws_eks_cluster.this.name
#   principal_arn = var.github_actions_role_arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

#   access_scope {
#     type = "cluster"
#   }

#   depends_on = [aws_eks_access_entry.github_actions]
# }
