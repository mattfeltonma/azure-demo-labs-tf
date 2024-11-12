output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the virtual network"
}

output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The id of the virtual network"
}

output "subnet_id_bastion" {
  value       = azurerm_subnet.subnet_bastion.id
  description = "The resource id of the Azure Bastion subnet"
}

output "subnet_id_dnsin" {
  value       = azurerm_subnet.subnet_dnsin.id
  description = "The resource id of the Private DNS Resolver Inbound endpoint subnet"
}

output "subnet_id_dnsout" {
  value       = azurerm_subnet.subnet_dnsout.id
  description = "The resource id of the Private DNS Resolver Outbound endpoint subnet"
}

output "subnet_id_pe" {
  value       = azurerm_subnet.subnet_pe.id
  description = "The resource id of the private endpoint subnet"
}

output "subnet_id_tools" {
  value       = azurerm_subnet.subnet_tools.id
  description = "The resource id of the tools subnet"
}

output "private_resolver_inbound_endpoint_ip" {
  value       = module.dns_resolver.inbound_endpoint_ip
  description = "The private DNS zone name for the inbound endpoint"
}