output "public_ip" {
  value = resource.azurerm_public_ip.ollama.ip_address
}

output "password" {
  sensitive = true
  value = random_password.password.result
}