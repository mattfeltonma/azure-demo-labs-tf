output "name" {
  value       = azurerm_private_dns_zone.zone.name
  description = "The name of the private dns zone"
}

output "id" {
  value       = azurerm_private_dns_zone.zone.id
  description = "The id of the private dns zone"
}