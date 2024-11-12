output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "route_table_id_agw" {
  value       = module.route_table_agw.id
  description = "The resource id of the Application Gateway route table"
}

output "route_table_id_app" {
  value       = module.route_table_app.id
  description = "The resource id of the application route table"
}

output "route_table_id_data" {
  value       = module.route_table_data.id
  description = "The resource id of the data route table"
}

output "route_table_id_mgmt" {
  value       = module.route_table_mgmt.id
  description = "The resource id of the management route table"
}

output "route_table_id_vint" {
  value       = module.route_table_vint.id
  description = "The resource id of the virtual network integration route table"
}

output "subnet_id_agw" {
  value       = azurerm_subnet.subnet_agw.id
  description = "The resource id of the Application Gateway subnet"
}

output "subnet_id_apim" {
  value       = azurerm_subnet.subnet_apim.id
  description = "The resource id of the API Management subnet"
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