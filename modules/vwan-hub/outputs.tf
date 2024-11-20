output "name" {
  value       = azurerm_virtual_hub.hub.name
  description = "The name of the virtual wan hub"
}

output "default_route_table_id" {
  value       = azurerm_virtual_hub.hub.default_route_table_id
  description = "The resource id of the default route table"
}

output "id" {
  value       = azurerm_virtual_hub.hub.id
  description = "The resource id of the virtual wan hub"
}