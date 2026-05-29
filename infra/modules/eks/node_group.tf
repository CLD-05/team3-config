#eks/node_group.tf

# EKS Worker Node Group 생성
resource "aws_eks_node_group" "this" {

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "team3-${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # [리팩토링] Team 태그 제거 → provider default_tags 로 이동, Name 만 유지
  tags = {
    Name = "team3-${var.cluster_name}-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}
