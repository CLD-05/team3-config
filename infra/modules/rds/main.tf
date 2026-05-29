#rds/main.tf

resource "aws_security_group" "rds_sg" {
  name        = "team3-${var.env}-rds-sg"
  description = "Security Group for RDS MySQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS Nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_sg_id, var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # [리팩토링] Team 태그 제거 → provider default_tags 로 이동, Name 만 유지
  tags = {
    Name = "team3-${var.env}-rds-sg"
  }
}

resource "aws_db_instance" "mysql" {
  # [리팩토링] identifier 에 team3 prefix 추가하여 다른 리소스와 네이밍 일관성 확보
  # [import] db_identifier 가 지정되면 그걸 쓰고, 아니면 기존 네이밍 규칙
  identifier            = var.db_identifier != "" ? var.db_identifier : "team3-${var.env}-foldy-db-server"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50

  db_name = "foldy"
  # [리팩토링] username 평문 하드코딩 제거 → var.db_username 사용
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = var.rds_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  availability_zone = "ap-northeast-2a"
  # [리팩토링] 선언만 되고 미사용이던 변수들을 실제 연결 (multi_az / 삭제보호 / 백업보존)
  multi_az = var.multi_az

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = var.rds_delete_protect
  backup_retention_period = var.rds_backup_retention_period

  tags = {
    Name = "team3-${var.env}-mysql"
  }
}
