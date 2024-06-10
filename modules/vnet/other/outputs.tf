output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "subnet_id_app" {
  value       = azurerm_subnet.subnet_app.id
  description = "The resource id of the application subnet"
}

output "subnet_id_data" {
  value       = azurerm_subnet.subnet_data.id
  description = "The resource id of the data subnet"
}

output "subnet_id_pe" {
  value       = azurerm_subnet.subnet_pe.id
  description = "The resource id of the private endpoint subnet"
}