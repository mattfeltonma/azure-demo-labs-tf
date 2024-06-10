output "name" {
  value       = azurerm_route_table.route_table.name
  description = "The name of the route table"
}

output "id" {
  value       = azurerm_route_table.route_table.id
  description = "The resource id of the route table"
}