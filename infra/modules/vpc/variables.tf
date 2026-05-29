#vpc/variables.tf

variable "env" {
  type        = string
  description = "배포 환경 (예: dev, prod)"
  default     = "dev"
}

variable "cluster_name" {
  type        = string
  description = "EKS 클러스터 이름 (서브넷 태그용)"
  # [리팩토링] 기본값이 CIDR("10.0.0.0/16")로 잘못 들어가 있어 제거.
  # 잘못된 값이 들어가면 kubernetes.io/cluster/<name> 태그가 엉뚱하게 붙어
  # EKS 서브넷 자동 디스커버리가 깨짐. 필수값이므로 default 미지정.
  default = ""
}
