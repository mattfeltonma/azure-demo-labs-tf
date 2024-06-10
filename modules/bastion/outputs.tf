output "name" {
  value       = azurerm_bastion_host.bastion.name
  description = "The name of the Azure Bastion instance"
}

output "id" {
  value       = azurerm_bastion_host.bastion.id
  description = "The resource id of the Azure Bastion instance"
}