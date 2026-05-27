variable "env" {
  type        = string
  description = "배포 환경 (예: dev, prod)"
  default     = "dev"
}

### private 서브넷 클러스터 태그 적용 시 필요합니다.
variable "cluster_name" {
  type        = string
  description = "EKS 클러스터 이름 (서브넷 태그용)"
  default     = "10.0.0.0/16"
}
