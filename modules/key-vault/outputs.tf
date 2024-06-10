output "name" {
  value       = azurerm_key_vault.kv.name
  description = "The name of the Azure Key Vault instance"
}

output "id" {
  value       = azurerm_key_vault.kv.id
  description = "The resource id of the Azure Key Vault instance"
}