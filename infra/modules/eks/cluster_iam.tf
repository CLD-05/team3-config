#eks/cluster_iam.tf

# EKS Control Plane용 IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "team3-${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # [리팩토링] 태그 지원 리소스인데 태그 누락 → Name 추가 (Team은 default_tags)
  tags = {
    Name = "team3-${var.cluster_name}-cluster-role"
  }
}
# EKS Cluster 기본 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
# [참고] aws_iam_role_policy_attachment 는 태그 미지원 리소스. 누락 아님
