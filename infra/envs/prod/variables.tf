#prod/variables.tf

variable "db_password" {
  type        = string
  description = "Root module DB password variable"
  sensitive   = true
}

variable "db_username" {
  type        = string
  description = "RDS 마스터 계정 이름"
  default     = "foldy"
}

variable "s3_bucket_name" {
  type        = string
  description = "App이 접근할 S3 버킷 이름"
  default     = "team3-foldy-storage"
}

variable "env" {
  type        = string
  description = "배포 환경 이름"
  default     = "prod"
}

variable "admin_user_arns" {
  description = "EKS 클러스터 admin 권한 IAM User ARN 목록"
  type        = list(string)
  default     = []
}

variable "rds_delete_protect" {
  type        = bool
  description = "RDS 삭제 보호 활성화 여부"
  default     = true
}

variable "rds_multi_az" {
  type        = bool
  description = "RDS 멀티 AZ 활성화 여부"
  default     = true
}

#bastion
variable "key_pair_name" {
  type        = string
  description = "Bastion SSH 접속용 키페어 이름"
}

# [리팩토링] 미사용 변수였음. force_destroy 를 쓰는 리소스가 prod main 에 없음.
# prod S3 는 dev 와 공유하며 버킷 자체를 생성하지 않으므로 이 변수는 불필요 → 제거
# (만약 prod 전용 버킷 생성 예정이면 해당 aws_s3_bucket 리소스에 연결할 것)

# [리팩토링] prod RDS 백업 보존 기간 변수 추가
variable "rds_backup_retention_period" {
  type        = number
  description = "RDS 자동 백업 보존 기간(일). prod 는 7일 이상 권장"
  default     = 7
}

# [리팩토링] bastion SSH 허용 CIDR (prod 는 반드시 좁혀서 사용)
variable "allowed_ssh_cidr" {
  type        = list(string)
  description = "Bastion SSH 접속 허용 CIDR 목록 (prod 는 회사/VPN IP 로 제한)"
  default     = ["0.0.0.0/0"]
}

variable "force_destroy" {
  type        = bool
  description = "S3 버킷 강제 삭제 여부. prod 는 false 권장"
  default     = false
}
