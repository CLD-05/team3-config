# GitHub Actions OIDC Role & Policy (ECR push용)
# =================================================================

# AWS 전역에 GitHub 자격 증명 공급자 등록
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

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

# 현재 로그인된 AWS 계정 ID를 실시간으로 캐치하는 안테나
data "aws_caller_identity" "current" {}

# ECR Push 실제 권한 지침서 (Policy)
# ECR Push 실제 권한 지침서 (Policy) - 모듈 동적 연동 및 팀 피드백 완벽 반영본!
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "dev-foldy-ecr-push-policy"
  description = "Allow GitHub Actions to push images to AWS ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        #  [Statement 1] AWS ECR 전체 서비스에 대한 로그인(인증) 권한
        Sid    = "ECRAuthAPI"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*" # 로그인 API는 리소스 제한이 안 되므로 "*" 고정 (피드백 반영)
      },
      {
        #  [Statement 2] ECR 리포지토리에 대한 정밀 제어 권한
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

        # 하드코딩 대신, 넘겨받은 URL 주소에서 레포지토리 이름만 쏙 뽑아내어 ARN을 동적으로 완성합니다!
        Resource = [
          "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.current.account_id}:repository/${split("/", var.ecr_repository_url)[1]}" #47 Line (data.aws_caller_identity.current.account_id)
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
