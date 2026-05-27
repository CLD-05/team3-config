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
  sensitive   = true # 패스워드가 로그나 콘솔에 평문 노출되는 것을 방지
}
