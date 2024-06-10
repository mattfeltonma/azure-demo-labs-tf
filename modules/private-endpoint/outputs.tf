output "id" {
  value       = azurerm_private_endpoint.pe.id
  description = "The resource id of the private endpoint"
}

output "name" {
  value       = azurerm_private_endpoint.pe.name
  description = "The name of the private endpoint"
}

output "private_endpoint_ip" {
  value       = azurerm_private_endpoint.pe.private_service_connection.0.private_ip_address
  description = "The private IP address of the private endpoint"
}