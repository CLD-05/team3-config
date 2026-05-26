# OIDC ARN에서 URL만 빼내기 위한 로컬 변수 처리
locals {
  oidc_provider_url = replace(var.eks_oidc_provider_arn, "/^(.*)oidc-provider//", "")
}

# AWS IAM Role 생성 (Trust Policy 포함)
resource "aws_iam_role" "app_irsa_role" {
  name = "${var.env}-app-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}",
        }
      }
      }

    ]
  })
}

# AWS IAM Policy 생성 (App이 사용할 S3 접근 권한)
resource "aws_iam_policy" "app_s3_policy" {
  name        = "${var.env}-app-s3-policy"
  path        = "/"
  description = "IAM policy for App Pod to access S3 via IRSA"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# IAM Role과 Policy 연결 (Attachment)
resource "aws_iam_role_policy_attachment" "app_irsa_attach" {
  role       = aws_iam_role.app_irsa_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}
