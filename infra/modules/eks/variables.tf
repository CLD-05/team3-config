#eks/variables.tf

variable "cluster_name" {
  description = "EKS 클러스터 이름 (예: team3-dev-eks, team3-prod-eks)"
  type        = string
}

variable "cluster_version" {
  description = "EKS 컨트롤 플레인 Kubernetes 버전"
  type        = string
  default     = "1.35"
}

variable "private_subnet_ids" {
  description = "EKS 클러스터/노드가 배치될 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "node_instance_types" {
  description = "워커 노드 EC2 인스턴스 타입 목록"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "노드 그룹 기본 노드 개수 (Auto Scaling 시작 시점 노드 수)"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "노드 그룹 최소 노드 개수 (Auto Scaling 하한)"
  type        = number
  default     = 0
}

variable "node_max_size" {
  description = "노드 그룹 최대 노드 개수 (Auto Scaling 상한)"
  type        = number
  default     = 2
}

variable "admin_user_arns" {
  description = "EKS 클러스터에 admin 권한을 가질 IAM User ARN 목록"
  type        = list(string)
  default     = []
}

variable "github_actions_role_arns" {
  description = "GitHub Actions IAM Role ARN 맵 (key: 식별자, value: Role ARN). 빈 맵이면 access entry 생성 안 함"
  type        = map(string)
  default     = {}
}

# [리팩토링] EKS API public access 변수화 (운영 전환 시 false)
variable "endpoint_public_access" {
  description = "EKS API 서버 퍼블릭 접근 허용 여부. 운영 전환 시 false 권장"
  type        = bool
  default     = true
}

#bastion
variable "bastion_sg_id" {
  type        = string
  description = "Bastion 보안그룹 ID"
}
