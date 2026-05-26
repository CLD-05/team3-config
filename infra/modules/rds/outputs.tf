#rds/outputs.tf

output "endpoint" {
  description = "K8s Secret 혹은 Spring Boot 환경 변수에 주입할 RDS 엔드포인트 주소"
  value       = aws_db_instance.mysql.endpoint
}

### K8s Secret에 주입할 때 db_name, username도 함께 필요합니다.
### 아래 두 output을 추가하세요.
output "db_name" {
  description = "RDS 데이터베이스 이름"
  value       = aws_db_instance.mysql.db_name
}

output "db_username" {
  description = "RDS 마스터 계정 이름"
  value       = aws_db_instance.mysql.username
}
