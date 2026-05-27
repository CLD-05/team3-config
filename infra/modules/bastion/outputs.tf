output "bastion_public_ip" {
  description = "Bastion EC2 퍼블릭 IP (SSH 접속용)"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Bastion EC2 인스턴스 ID"
  value       = aws_instance.bastion.id
}

output "bastion_sg_id" {
  description = "Bastion 보안그룹 ID"
  value       = aws_security_group.bastion_sg.id
}
