variable "env" {
  description = "배포 환경 (dev / prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름 (서브넷 태그용)"
  type        = string
}
