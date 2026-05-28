#dev/variables.tf

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

variable "env" {
  type        = string
  description = "배포 환경 이름"
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

variable "force_destroy" {
  type        = bool
  description = "S3 버킷 내부에 존재하는 모든 파일 삭제 활성화 여부 (true/false)"
}

