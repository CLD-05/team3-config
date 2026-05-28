# modules/vpc/main.tf

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "team3-${var.env}-vpc"
    Team = "team3"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "team3-${var.env}-igw"
    Team = "team3"
  }
}

# 퍼블릭 서브넷
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "team3-${var.env}-subnet-public-a"
    "kubernetes.io/role/elb" = "1"
    Team                     = "team3"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "team3-${var.env}-subnet-public-c"
    "kubernetes.io/role/elb" = "1"
    Team                     = "team3"
  }
}

# 프라이빗 서브넷 (EKS 노드용)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                                        = "team3-${var.env}-subnet-private-a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Team                                        = "team3"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name                                        = "team3-${var.env}-subnet-private-c"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Team                                        = "team3"
  }
}

# DB 서브넷
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "team3-${var.env}-subnet-db-a"
    Team = "team3"
  }
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "team3-${var.env}-subnet-db-c"
    Team = "team3"
  }
}

# ─────────────────────────────────────────────────────────────────
# 가용영역 2a용 NAT 게이트웨이 및 EIP (기본 구동)[수정 및 추가]
# ─────────────────────────────────────────────────────────────────
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags   = { Name = "team3-${var.env}-nat-a-eip", Team = "team3" }
}

resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "team3-${var.env}-nat-gw-a"
    Team = "team3"
  }
  depends_on = [aws_internet_gateway.igw]
}

# ─────────────────────────────────────────────────────────────────
# 가용영역 2c용 NAT 게이트웨이 및 EIP (prod 환경에서만 생성)[추가] 
# ─────────────────────────────────────────────────────────────────
resource "aws_eip" "nat_c" {
  count  = var.env == "prod" ? 1 : 0
  domain = "vpc"
  tags   = { Name = "team3-${var.env}-nat-c-eip", Team = "team3" }
}

resource "aws_nat_gateway" "nat_gw_c" {
  count         = var.env == "prod" ? 1 : 0
  allocation_id = aws_eip.nat_c[0].id
  subnet_id     = aws_subnet.public_c.id

  tags = {
    Name = "team3-${var.env}-nat-gw-c"
    Team = "team3"
  }
  depends_on = [aws_internet_gateway.igw]
}

# ─────────────────────────────────────────────────────────────────
# 라우트 테이블 분리 및 최적화
# ─────────────────────────────────────────────────────────────────

# 퍼블릭 라우트 테이블 (공통)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "team3-${var.env}-rt-public", Team = "team3" }
}

# 프라이빗 라우트 테이블 A (2a 영역 서버들이 사용)
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }

  tags = { Name = "team3-${var.env}-rt-private-a", Team = "team3" }
}

# 프라이빗 라우트 테이블 C (2c 영역 서버들이 사용 — prod일 때는 nat_gw_c 사용, dev일 때는 nat_gw_a로 대체)
resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.env == "prod" ? aws_nat_gateway.nat_gw_c[0].id : aws_nat_gateway.nat_gw_a.id
  }

  tags = { Name = "team3-${var.env}-rt-private-c", Team = "team3" }
}

# ─────────────────────────────────────────────────────────────────
# 라우트 테이블 어소시에이션 (연결 매핑 정비)
# ─────────────────────────────────────────────────────────────────

# 퍼블릭 서브넷 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# 프라이빗 서브넷 연결 (A는 rt_private_a로, C는 rt_private_c로 완벽 격리)
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private_c.id
}

# DB 서브넷 연결
resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "db_c" {
  subnet_id      = aws_subnet.db_c.id
  route_table_id = aws_route_table.private_c.id
}

# RDS 서브넷 그룹
resource "aws_db_subnet_group" "rds_group" {
  name       = "team3-${var.env}-rds-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_c.id]

  tags = {
    Name = "team3-${var.env}-rds-subnet-group"
    Team = "team3"
  }
}

# VPC 기본 라우팅 테이블 태그
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = "team3-${var.env}-rt-default"
    Team = "team3"
  }
}
