variable "env" {
  type        = string
  description = "배포 환경 (예: dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type        = string
  description = "Bastion이 배치될 퍼블릭 서브넷 ID"
}

variable "key_pair_name" {
  type        = string
  description = "SSH 접속용 키페어 이름"
}

variable "ami_id" {
  type        = string
  description = "Bastion EC2 AMI ID (ap-northeast-2 Ubuntu 22.04)"
  # Ubuntu 22.04 LTS ap-northeast-2
  default = "ami-042e76978adeb8c48"
}
