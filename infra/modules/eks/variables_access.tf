variable "admin_user_arns" {
  description = "EKS 클러스터에 admin 권한을 가질 IAM User ARN 목록"
  type        = list(string)
  default     = []
}

variable "github_actions_role_arn" {
  description = "GitHub Actions가 사용할 IAM Role ARN (CD용)"
  type        = string
  default     = ""
}
