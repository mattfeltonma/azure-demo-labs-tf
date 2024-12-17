output "name" {
  value       = azurerm_storage_account.storage_account.name
  description = "The name of the storage account"
}

output "id" {
  value       = azurerm_storage_account.storage_account.id
  description = "The resource id of the storage account"
}

output "endpoint_blob" {
  value       = azurerm_storage_account.storage_account.primary_blob_endpoint
  description = "The endpoint URL for blob storage"
}

output "endpoint_file" {
  value       = azurerm_storage_account.storage_account.primary_file_endpoint
  description = "The endpoint URL for file storage"
}