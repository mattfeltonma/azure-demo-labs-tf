output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "route_table_id_app" {
  value       = module.route_table_app.id
  description = "The resource id of the route table for the application subnet"
}

output "route_table_id_svc" {
  value       = module.route_table_svc.id
  description = "The resource id of the route table for the services subnet"
}

output "subnet_id_app" {
  value       = azurerm_subnet.subnet_app.id
  description = "The resource id of the application subnet"
}

output "subnet_id_svc" {
  value       = azurerm_subnet.subnet_svc.id
  description = "The resource id of the services subnet"
}