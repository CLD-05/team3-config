#vpc/variables.tf

### variables.tf 파일이 없습니다.
### vpc/main.tf의 모든 태그와 이름이 하드코딩되어 있으므로
### 아래 변수들을 추가하고 dev/main.tf의 module "vpc" 블록에서 넘겨주세요.

variable "env" {
  type        = string
  description = "배포 환경 (예: dev, prod)"
  default     = "dev"
}

### private 서브넷 클러스터 태그 적용 시 필요합니다.
variable "cluster_name" {
  type        = string
  description = "EKS 클러스터 이름 (서브넷 태그용)"
  default     = ""
}
