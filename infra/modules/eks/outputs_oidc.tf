output "oidc_provider_arn" {
  description = "EKS OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "EKS OIDC Provider URL (https:// 제외)"
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}
