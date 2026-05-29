#ecr/variables.tf

variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

# [리팩토링] image_tag_mutability 변수 추가 (환경별 제어)
variable "image_tag_mutability" {
  description = "이미지 태그 변경 가능 여부 (MUTABLE / IMMUTABLE). prod는 IMMUTABLE 권장"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability 는 MUTABLE 또는 IMMUTABLE 이어야 합니다."
  }
}
