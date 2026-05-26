<<<<<<< HEAD
variable "ecr_repository_url" {
  type        = string
  description = "ECR 모듈에서 넘겨받을 리포지토리 주소 URL"
=======
variable "env" {
  type        = string
  description = "배포 환경 (예: dev, prod)"
  default     = "dev"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "EKS 클러스터의 IAM OIDC Provider ARN"
}

variable "k8s_namespace" {
  type        = string
  description = "K8s 애플리케이션이 배포될 네임스페이스"
  default     = "app"
}

variable "k8s_service_account_name" {
  type        = string
  description = "K8s Pod가 사용할 ServiceAccount 이름"
  default     = "app-sa"
}

variable "s3_bucket_name" {
  type        = string
  description = "App이 접근할 S3 버킷 이름"
>>>>>>> origin/feature/KEJ_20260526/iam1
}
