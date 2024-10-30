output "firewall_ilb_ip" {
  value = module.ilb.ip_address
  description = "The IP address of the load balancer in front of the NVAs"
}

output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "route_table_id_gateway" {
  value       = module.route_table_gateway.id
  description = "The id of the route table associated with the GatewaySubnet"
}

output "route_table_name_gateway" {
  value       = module.route_table_gateway.name
  description = "The resource name of the route table associated with the GatewaySubnet"
}

output "route_table_id_firewall_private" {
  value       = module.route_table_firewall_private.id
  description = "The id of the route table associated with the NVA private subnet"
}

output "route_table_name_firewall_private" {
  value       = module.route_table_firewall_private.name
  description = "The resource name of the route table associated with the NVA private subnet"
}

output "route_table_id_firewall_public" {
  value       = module.route_table_firewall_public.id
  description = "The id of the route table associated with the NVA public subnet"
}

output "route_table_name_firewall_public" {
  value       = module.route_table_firewall_public.name
  description = "The resource name of the route table associated with the NVA public subnet"
}

output "subnet_id_gateway" {
  value       = azurerm_subnet.subnet_gateway.id
  description = "The resource id of the GatewaySubnet subnet"
}

output "subnet_id_firewall_private" {
  value       = azurerm_subnet.subnet_firewall_private.id
  description = "The resource id of the NVA private subnet"
}

output "subnet_name_firewall_private" {
  value       = azurerm_subnet.subnet_firewall_private.name
  description = "The resource name of the NVA private subnet"
}

output "subnet_id_firewall_public" {
  value       = azurerm_subnet.subnet_firewall_public.id
  description = "The resource id of the NVA public subnet"
}

output "subnet_name_firewall_public" {
  value       = azurerm_subnet.subnet_firewall_public.name
  description = "The resource name of the NVA private subnet"
}