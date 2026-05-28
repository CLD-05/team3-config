#rds/main.tf

resource "aws_security_group" "rds_sg" {
  ### SG 이름이 "dev-foldy-rds-sg"로 하드코딩되어 있습니다.
  ### iam/main.tf에서 지적한 것과 동일하게 var.env 변수를 추가해
  ### "${var.env}-foldy-rds-sg"로 변경하면 prod 환경 분리 시 재사용할 수 있습니다.
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

  tags = {
    ### 태그도 동일하게 var.env로 변경하세요.
    Name = "team3-${var.env}-rds-sg"
    Team = "team3"
  }
}

resource "aws_db_instance" "mysql" {
  ### identifier, tags.Name도 동일하게 var.env로 변경하세요.
  identifier            = "dev-foldy-db-server"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50

  db_name  = "foldy"
  username = "foldy"
  ### username도 평문 하드코딩입니다. var.db_username 변수로 분리하세요.
  password = var.db_password

  db_subnet_group_name   = var.rds_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  availability_zone = "ap-northeast-2a"
  multi_az          = false

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "team3-${var.env}-mysql"
  }
}
