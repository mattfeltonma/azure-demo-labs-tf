output "application_rule_collection_group_id" {
  value       = azurerm_firewall_policy_rule_collection_group.rule_collection_group_enterprise.id
  description = "The id of the rule collection group used for enterprise-wide rules"
}

output "dnat_rule_collection_group_id" {
  value       = azurerm_firewall_policy_rule_collection_group.rule_collection_group_workload.id
  description = "The id of the rule collection group used for workload rules"
}

output "name" {
  value       = azurerm_firewall.firewall.name
  description = "The name of the Azure Firewall instance"
}

output "id" {
  value       = azurerm_firewall.firewall.id
  description = "The id of the Azure Firewall instance"
}

output "private_ip" {
  value       = try(azurerm_firewall.firewall.ip_configuration[0].private_ip_address, null)
  description = "The private IP address of the Azure Firewall instance with a hub and spoke configuration"
}

output "private_ip_vwan_hub" {
    value       = try(azurerm_firewall.firewall.virtual_hub[0].private_ip_address, null)
    description = "The private IP address of the Azure Firewall instance with a vWAN hub configuration"
}

output "policy_id" {
  value       = azurerm_firewall_policy.firewall_policy.id
  description = "The id of the Azure Firewall Policy"
}
