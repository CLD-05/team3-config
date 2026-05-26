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

variable "admin_user_arns" {
  description = "EKS 클러스터 admin 권한 IAM User ARN 목록"
  type        = list(string)
  default     = []
}
