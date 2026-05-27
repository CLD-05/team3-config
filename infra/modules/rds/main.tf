resource "aws_security_group" "rds_sg" {
  name        = "dev-foldy-rds-sg"
  description = "Security Group for RDS MySQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS Nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_sg_id] # EKS 노드 보안 그룹 ID를 소스로 걸어 격리
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-foldy-rds-sg"
  }
}

# 2. AWS RDS DB Instance 생성 (MySQL 8.0 싱글 AZ 가성비 세팅)
resource "aws_db_instance" "mysql" {
  identifier            = "dev-foldy-db-server"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro" # DEV용 초소형/저비용 인스턴스 사양
  allocated_storage     = 20
  max_allocated_storage = 50 # 용량 부족 시 자동 스케일링 허용

  db_name  = "foldy"
  username = "foldy"
  password = var.db_password

  # VPC 모듈과 보안 그룹 연동
  db_subnet_group_name   = var.rds_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # 다이어그램 사양 고정 (싱글 AZ로 비용 최소화)
  availability_zone = "ap-northeast-2a" # 실제 인스턴스는 2a에만 생성
  multi_az          = false             # Multi-AZ 복제 비활성화

  # 실습 편의성 옵션
  publicly_accessible = false #  외부 인터넷 접속 차단
  skip_final_snapshot = true  # terraform destroy 시 최종 스냅샷 생성 안 함
  # 실수로 인프라가 날아가는 것을 방지하는 안전장치
  deletion_protection = false # 현재 DEV 환경이므로 false로 두어 삭제를 허용하지만, 추후 PROD(운영) 환경 전환 시 반드시 true로 변경

  tags = {
    Name = "dev-foldy-mysql"
  }
}
