# 최상위 폴더의 variables.tf 파일

variable "db_password" {
  type        = string
  description = "Root module DB password variable"
  sensitive   = true # 패스워드가 콘솔이나 로그에 평문으로 찍히는 것을 방지
}
