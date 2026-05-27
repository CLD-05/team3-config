# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env}-foldy-vpc"
  }
}

# 인터넷 게이트웨이 (퍼블릭 통신용)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-foldy-igw"
  }
}

# 퍼블릭 서브넷 (2개 - 2c는 구조적 요구사항 대응용)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.env}-subnet-public-a"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.env}-subnet-public-c"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# 프라이빗 서브넷 (2개 - EKS Node 및 ASG 배포용)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                                        = "${var.env}-subnet-private-a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name                                        = "${var.env}-subnet-private-c"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# DB 서브넷 (2개 - RDS Subnet Group 생성 제약조건 해결용)
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.env}-subnet-db-a"
  }
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.env}-subnet-db-c"
  }
}

# NAT 게이트웨이 및 EIP (비용 절감을 위해 1개만 생성)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.env}-nat-eip" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.env}-nat-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}

# 라우트 테이블 (퍼블릭 / 프라이빗)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.env}-rt-public" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = { Name = "${var.env}-rt-private" }
}

# 라우트 테이블 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

# RDS 서브넷 그룹
resource "aws_db_subnet_group" "rds_group" {
  name       = "${var.env}-foldy-rds-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_c.id]

  tags = {
    Name = "${var.env}-foldy-rds-subnet-group"
  }
}
