#eks/oidc.tf✅

# EKS 클러스터의 TLS 인증서 가져오기 (Thumbprint 추출용)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# EKS OIDC Provider 등록
resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = {
    Name = "team3-${aws_eks_cluster.this.name}-oidc"
    Team = "team3"
  }
}
