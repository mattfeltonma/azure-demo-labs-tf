output "name" {
  value       = azurerm_public_ip.pip.name
  description = "The name of the public ip"
}

output "id" {
  value       = azurerm_public_ip.pip.id
  description = "The id of the public ip"
}

output "ip_address" {
  value       = azurerm_public_ip.pip.ip_address
  description = "The ip address of the public ip"
}