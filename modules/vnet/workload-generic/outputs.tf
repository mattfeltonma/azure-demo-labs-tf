output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "subnet_id_agw" {
  value       = azurerm_subnet.subnet_agw.id
  description = "The resource id of the Application Gateway subnet"
}

output "subnet_id_app" {
  value       = azurerm_subnet.subnet_app.id
  description = "The resource id of the application subnet"
}

output "subnet_id_data" {
  value       = azurerm_subnet.subnet_data.id
  description = "The resource id of the data subnet"
}

output "subnet_id_mgmt" {
  value       = azurerm_subnet.subnet_mgmt.id
  description = "The resource id of the management subnet"
}

output "subnet_id_svc" {
  value       = azurerm_subnet.subnet_svc.id
  description = "The resource id of the services subnet"
}

output "subnet_id_vint" {
  value       = azurerm_subnet.subnet_vint.id
  description = "The resource id of the virtual network integration subnet"
}