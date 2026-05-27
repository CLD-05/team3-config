output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = [aws_subnet.private_a.id, aws_subnet.private_c.id]
}

output "rds_subnet_group_name" {
  description = "The name of the RDS database subnet group"
  value       = aws_db_subnet_group.rds_group.name
}
# DB 서브넷 ID 리스트 아웃풋 추가
output "db_subnet_ids" {
  description = "List of IDs of DB subnets"
  value       = [aws_subnet.db_a.id, aws_subnet.db_c.id]
}
