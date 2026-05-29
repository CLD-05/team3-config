#eks/cluster.tf

# EKS Control Plane 생성
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
    ### endpoint_public_access = true 는 인터넷에서 API 서버 접근이 가능한 상태입니다.
    ### 학습 환경이라 불가피하지만, 실제 운영 전환 시 false로 변경하고
    ### Bastion 또는 VPN을 통한 private 접근으로 전환하세요.
    # [리팩토링] public access 를 변수화하여 운영 전환 시 false 로 제어 가능
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
  }

  ### 부트캠프 환경 권한 제한으로 적용 불가 (eks:UpdateClusterConfig 권한 없음)
  ### 신규 클러스터 생성 시에는 아래 주석 해제 후 apply 하세요.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # [리팩토링] Team 태그 제거 → provider default_tags 로 이동, Name 만 유지
  tags = {
    Name = "team3-${var.cluster_name}-cluster"
  }

  timeouts {
    create = "30m"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

#bastion
resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description              = "Bastion to EKS API Server"
}
# [참고] aws_security_group_rule 은 태그 미지원 리소스. 누락 아님
