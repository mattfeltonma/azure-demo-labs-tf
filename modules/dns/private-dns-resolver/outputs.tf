output "name" {
  value       = azurerm_private_dns_resolver.resolver.name
  description = "The name of the Private DNS Resolver"
}

output "id" {
  value       = azurerm_private_dns_resolver.resolver.id
  description = "The id of the private dns resolver"
}
output "inbound_endpoint_ip" {
  value       = azurerm_private_dns_resolver_inbound_endpoint.inend.ip_configurations[0].private_ip_address
  description = "The private IP address of the inbound resolver endpoint"
}