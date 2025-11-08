output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "monitor_server_public_ip" {
  description = "Public IP address of the monitor server"
  value       = aws_instance.monitor.public_ip
}

output "monitor_server_public_dns" {
  description = "Public DNS of the monitor server"
  value       = aws_instance.monitor.public_dns
}

output "app_server_public_ip" {
  description = "Public IP address of the app server"
  value       = aws_instance.app.public_ip
}

output "app_server_public_dns" {
  description = "Public DNS of the app server"
  value       = aws_instance.app.public_dns
}

output "db_server_private_ip" {
  description = "Private IP address of the database server"
  value       = aws_instance.db.private_ip
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to monitor server"
  value       = "ssh -i id_rsa ubuntu@${aws_instance.monitor.public_ip}"
}

output "app_url" {
  description = "URL to access the app server"
  value       = "http://${aws_instance.app.public_ip}"
}

output "environment_summary" {
  description = "Summary of the deployed environment"
  value       = <<EOT
  Environment: ${var.environment_id}
  Monitor Server: ${aws_instance.monitor.public_ip} (SSH: ssh -i id_rsa ubuntu@${aws_instance.monitor.public_ip})
  App Server: ${aws_instance.app.public_ip} (SSH: ssh -i id_rsa ubuntu@${aws_instance.app.public_ip})
  Database Server: ${aws_instance.db.private_ip} (Private subnet with NAT Gateway: ${aws_eip.nat.public_ip})
  NAT Gateway: ${aws_eip.nat.public_ip} ✅ Enabled
  Access URL: http://${aws_instance.app.public_ip}
  EOT
}