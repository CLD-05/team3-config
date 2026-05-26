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
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  timeouts {
    create = "30m"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
