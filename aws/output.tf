output "public_ip" {
  value = aws_spot_instance_request.ollama.public_ip
}

output "password" {
  sensitive = true
  value = random_password.password.result
}