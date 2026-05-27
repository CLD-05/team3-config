#iam/main.tf

# GitHub Actions OIDC Role & Policy (ECR push용)
# =================================================================

# AWS 전역에 GitHub 자격 증명 공급자 등록
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      ### StringLike + 와일드카드(*)는 모든 브랜치/이벤트에서 Role Assume이 가능합니다.
      ### 테스트 완료 후 아래와 같이 반드시 변경하세요.
      ### test     = "StringEquals"
      ### values   = ["repo:CLD-05/team3-app:ref:refs/heads/main"]
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:CLD-05/team3-testApp:*"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "github_actions_ecr_role" {
  ### Role 이름이 "dev-foldy-github-actions-ecr-role"로 하드코딩되어 있습니다.
  ### var.env를 활용해 "${var.env}-foldy-github-actions-ecr-role"로 변경하면(변경완료)
  ### prod 환경 분리 시 그대로 재사용할 수 있습니다.
  name               = "${var.env}-foldy-github-actions-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_policy" "ecr_push_policy" {
  ### Policy 이름도 동일하게 하드코딩되어 있습니다.
  ### "${var.env}-foldy-ecr-push-policy"로 변경하세요.(변경 완료)
  name        = "${var.env}-foldy-ecr-push-policy"
  description = "Allow GitHub Actions to push images to AWS ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuthAPI"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRRepositoryActions"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        ### ecr_repository_url에서 split으로 레포 이름을 추출하는 방식은
        ### URL 형식이 바뀌면 조용히 깨질 수 있습니다.
        ### ecr 모듈 outputs.tf에 repository_arn을 추가하고
        ### 해당 ARN을 직접 받아 사용하는 방식으로 변경하세요.(변경 완료)
        Resource = [var.ecr_repository_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_attach" {
  role       = aws_iam_role.github_actions_ecr_role.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}

locals {
  oidc_provider_url = replace(var.eks_oidc_provider_arn, "/^(.*)oidc-provider//", "")
}

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
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"
        }
      }
    }]
  })
}

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

resource "aws_iam_role_policy_attachment" "app_irsa_attach" {
  role       = aws_iam_role.app_irsa_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}
