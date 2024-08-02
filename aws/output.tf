output "public_ip" {
  value = aws_spot_instance_request.open_web_ui.public_ip
}

output "password" {
  sensitive = true
  value = random_password.password.result
}