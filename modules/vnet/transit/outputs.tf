output "azfw_private_ip" {
  value = module.firewall.private_ip
  description = "The private IP address of the Azure Firewall"
}

output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "policy_id" {
  value       = module.firewall.policy_id
  description = "The id of the Azure Firewall Policy"
}

output "route_table_id_gateway" {
  value       = module.route_table_gateway.id
  description = "The id of the route table associated with the GatewaySubnet"
}

output "route_table_name_gateway" {
  value       = module.route_table_gateway.name
  description = "The name of the route table associated with the GatewaySubnet"
}

output "subnet_id_gateway" {
  value       = azurerm_subnet.subnet_gateway.id
  description = "The resource id of the GatewaySubnet subnet"
}

output "subnet_id_firewall" {
  value       = azurerm_subnet.subnet_firewall.id
  description = "The resource id of the AzureFirewallSubnet subnet"
}