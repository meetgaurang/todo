output "app_url" {
  description = "URL to access the todo app"
  value       = "http://${aws_instance.todo_app.public_dns}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.todo_app.public_dns}"
}
