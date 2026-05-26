#eks/variables.tf

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  ### dev/main.tf에서 "1.30"을 넘기고 있는데 default가 "1.29"입니다.
  ### 프로젝트 스택 기준(EKS 1.30)에 맞게 default = "1.30"으로 변경하세요.
  default = "1.29"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS cluster"
  type        = list(string)
}

variable "node_instance_types" {
  ### description이 없습니다. 추가하세요.
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  ### description이 없습니다. 추가하세요.
  type    = number
  default = 2
}

variable "node_min_size" {
  ### description이 없습니다. 추가하세요.
  type    = number
  default = 0
}

variable "node_max_size" {
  ### description이 없습니다. 추가하세요.
  type    = number
  default = 2
}

variable "admin_user_arns" {
  description = "EKS 클러스터에 admin 권한을 가질 IAM User ARN 목록"
  type        = list(string)
  default     = []
}

variable "github_actions_role_arn" {
  description = "GitHub Actions가 사용할 IAM Role ARN (CD용)"
  type        = string
  default     = ""
}
