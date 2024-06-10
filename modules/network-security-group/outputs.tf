output "name" {
  value       = azurerm_network_security_group.nsg.name
  description = "The name of the network security group"
}

output "id" {
  value       = azurerm_network_security_group.nsg.id
  description = "The resource id of the network security group"
}