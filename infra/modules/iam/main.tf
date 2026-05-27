# GitHub Actions OIDC Role & Policy (ECR push용)
# =================================================================

# AWS 전역에 GitHub 자격 증명 공급자 등록
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 현재 로그인된 AWS 계정 ID를 실시간으로 캐치하는 안테나
data "aws_caller_identity" "current" {}

# 내 깃허브 레포의 main 브랜치만 허용하는 신뢰 관계(Trust Policy) 정의
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement { # ID/PW 대신 웹 인증서 토큰으로 임시 출입증(AWS가 발행한 토큰) 교환 허용
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition { # 깃허브 액션이 발급받은 일회용 명찰(GitHub Actions가 발행한 토큰)의 수신처(Audience)를 검사 
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 힌트: ...sub": "repo:org/repo:ref:refs/heads/main"
    condition {
      test = "StringLike" # 테스트용 느슨한 일치 보안이 약하니 테스트 할 때만
      # test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:CLD-05/team3-testApp:*"] # 테스트용 team3-testApp 깃으로 연결 됨
      # values = ["repo:CLD-05/team3-App:ref:refs/heads/main"]
    }

    # 힌트: Principal Federated: token.actions.githubusercontent.com
    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated" #연합 인증(AWS 외부의 거대한 웹 시스템과 계정 체계를 연동할 때)
    }
  }
}

# aws_iam_role 생성 (위의 OIDC 조건문 포함)
resource "aws_iam_role" "github_actions_ecr_role" {
  name               = "dev-foldy-github-actions-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# ECR Push 실제 권한 지침서 (Policy)
# ECR Push 실제 권한 지침서 (Policy) - 모듈 동적 연동 및 팀 피드백 완벽 반영본!
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "dev-foldy-ecr-push-policy"
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
        Resource = [
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/${split("/", var.ecr_repository_url)[1]}"
        ]
      }
    ]
  })
}

# aws_iam_role_policy_attachment (ECR push 권한을 롤에 묶기)
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
