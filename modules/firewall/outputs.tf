output "application_rule_collection_group_id" {
  value       = azurerm_firewall_policy_rule_collection_group.rule_collection_group_application.id
  description = "The id of the application rule collection group"
}

output "dnat_rule_collection_group_id" {
  value       = azurerm_firewall_policy_rule_collection_group.rule_collection_group_dnat.id
  description = "The id of the DNAT rule collection group"
}

output "name" {
  value       = azurerm_firewall.firewall.name
  description = "The name of the Azure Firewall instance"
}

output "network_rule_collection_group_id" {
  value       = azurerm_firewall_policy_rule_collection_group.rule_collection_group_network.id
  description = "The id of the network rule collection group"
}

output "id" {
  value       = azurerm_firewall.firewall.id
  description = "The id of the Azure Firewall instance"
}

output "private_ip" {
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  description = "The private IP address of the Azure Firewall instance"
}

output "policy_id" {
  value       = azurerm_firewall_policy.firewall_policy.id
  description = "The id of the Azure Firewall Policy"
}
