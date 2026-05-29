#rds/variables.tf

variable "vpc_id" {
  type        = string
  description = "VPC ID (VPC 모듈의 vpc_id 아웃풋을 주입)"
}

variable "rds_subnet_group_name" {
  type        = string
  description = "VPC 모듈에서 생성한 DB 서브넷 그룹의 이름"
}

variable "eks_sg_id" {
  type        = string
  description = "EKS 워커 노드의 보안 그룹 ID (EKS 모듈 아웃풋을 주입)"
}

variable "db_password" {
  type        = string
  description = "MySQL 마스터 계정 비밀번호"
  sensitive   = true
}

variable "db_username" {
  type        = string
  description = "MySQL 마스터 계정 이름"
  default     = "foldy"
}

variable "env" {
  type        = string
  description = "배포 환경 (예: dev, prod)"
  default     = "dev"
}

variable "rds_delete_protect" {
  type        = bool
  description = "루트 모듈로부터 전달받은 삭제 보호 여부"
  default     = false
}

variable "multi_az" {
  type        = bool
  description = "루트 모듈로부터 전달받은 Multi-AZ 여부"
  default     = false
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS 자동 백업 보존 기간"
  default     = 0
}

variable "bastion_sg_id" {
  type        = string
  description = "Bastion 보안그룹 ID"
  default     = ""
}

# [import] 기존 RDS identifier 유지용. 마이그레이션 직후 이름 변경(재부팅/엔드포인트 변경) 방지
variable "db_identifier" {
  type        = string
  description = "RDS 인스턴스 식별자. 기존 리소스와 일치시켜 불필요한 변경 방지"
  default     = ""
}
