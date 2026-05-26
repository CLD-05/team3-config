output "endpoint" {
  description = "K8s Secret 혹은 Spring Boot 환경 변수에 주입할 RDS 엔드포인트 주소"
  value       = aws_db_instance.mysql.endpoint
}
