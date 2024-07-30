output "public_ip" {
  value = aws_instance.ollama.public_ip
}

output "password" {
  sensitive = true
  value = random_password.password.result
}