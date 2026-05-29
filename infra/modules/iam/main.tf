#iam/main.tf

# GitHub Actions OIDC Role & Policy (ECR push용)
# =================================================================

# AWS 전역에 GitHub 자격 증명 공급자 등록
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
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
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:CLD-05/team3-app:ref:refs/heads/main",
        "repo:CLD-05/team3-app:ref:refs/tags/*"
      ]
    }

    principals {
      #  앞에 data. 를 꼭 붙여주어야 에러가 나지 않습니다.
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "github_actions_ecr_role" {
  name               = "team3-${var.env}-foldy-github-actions-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.env}-foldy-github-actions-ecr-role"
  }
}

resource "aws_iam_policy" "ecr_push_policy" {
  name        = "team3-${var.env}-foldy-ecr-push-policy"
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
        Resource = [var.ecr_repository_arn]
      }
    ]
  })

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.env}-foldy-ecr-push-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_ecr_attach" {
  role       = aws_iam_role.github_actions_ecr_role.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}
# [참고] aws_iam_role_policy_attachment 는 태그 미지원 리소스. 누락 아님

# [리팩토링] 정규식 슬래시 이스케이프 오류 수정
# 기존: "/^(.*)oidc-provider//" → 슬래시가 잘못되어 치환이 동작하지 않음
# arn:aws:iam::<acct>:oidc-provider/<url> 에서 oidc-provider/ 까지를 제거하도록 수정
locals {
  oidc_provider_url = replace(var.eks_oidc_provider_arn, "/^arn:aws:iam::[0-9]+:oidc-provider\\//", "")
}

resource "aws_iam_role" "app_irsa_role" {
  name = "team3-${var.env}-app-irsa-role"

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

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.env}-app-irsa-role"
  }
}

resource "aws_iam_policy" "app_s3_policy" {
  name        = "team3-${var.env}-app-s3-policy"
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

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.env}-app-s3-policy"
  }
}

resource "aws_iam_role_policy_attachment" "app_irsa_attach" {
  role       = aws_iam_role.app_irsa_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}

# ALB Controller IRSA Role
resource "aws_iam_role" "alb_controller_irsa_role" {
  name = "team3-${var.env}-alb-controller-irsa-role"

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
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.env}-alb-controller-irsa-role"
  }
}

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "team3-${var.env}-alb-controller-policy"
  policy = file("${path.module}/alb_controller_policy.json")

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.env}-alb-controller-policy"
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_irsa_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}
