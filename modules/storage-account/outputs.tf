output "name" {
  value       = azurerm_storage_account.storage_account.name
  description = "The name of the storage account"
}

output "id" {
  value       = azurerm_storage_account.storage_account.id
  description = "The resource id of the storage account"
}