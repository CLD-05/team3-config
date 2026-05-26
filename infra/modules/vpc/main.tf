#vpc/main.tf

resource "aws_vpc" "main" {
  ### CIDR, 태그 등이 하드코딩되어 있습니다.
  ### rds/main.tf, iam/main.tf와 동일하게 var.env를 추가해
  ### 태그를 "${var.env}-foldy-vpc"로 변경하면 prod 분리 시 재사용할 수 있습니다.
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev-foldy-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-foldy-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "dev-subnet-public-a"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "dev-subnet-public-c"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                              = "dev-subnet-private-a"
    "kubernetes.io/role/internal-elb" = "1"
    ### EKS 노드가 배포되는 서브넷에는 클러스터 이름 태그도 추가해야
    ### AWS Load Balancer Controller가 서브넷을 자동으로 인식합니다.
    ### "kubernetes.io/cluster/${var.cluster_name}" = "shared" 를 추가하세요.
    ### var.cluster_name 변수를 vpc 모듈에 추가하거나
    ### 태그를 eks 모듈에서 aws_ec2_tag 리소스로 붙이는 방법 중 하나를 선택하세요.
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name                              = "dev-subnet-private-c"
    "kubernetes.io/role/internal-elb" = "1"
    ### private_a와 동일하게 클러스터 이름 태그를 추가하세요.
  }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "dev-subnet-db-a"
  }
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "dev-subnet-db-c"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "dev-nat-eip" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "dev-nat-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "dev-rt-public" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = { Name = "dev-rt-private" }
}

### DB 서브넷용 라우트 테이블이 없습니다.
### db_a, db_c 서브넷이 현재 어떤 라우트 테이블에도 연결되어 있지 않아
### VPC 기본 라우트 테이블을 타게 됩니다.
### aws_route_table_association으로 private 라우트 테이블에 명시적으로 연결하세요.
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

resource "aws_db_subnet_group" "rds_group" {
  name       = "dev-foldy-rds-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_c.id]

  tags = {
    Name = "dev-foldy-rds-subnet-group"
  }
}
