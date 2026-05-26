output "app_irsa_role_arn" {
  value       = aws_iam_role.app_irsa_role.arn
  description = "The ARN of the IAM Role to be annotated on the Kubernetes ServiceAccount (eks.amazonaws.com/role-arn)"
}
