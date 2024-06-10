output "client_id" {
  value       = azurerm_user_assigned_identity.umi.client_id
  description = "The resource Entra ID client id of the user assigned managed identity"
}

output "id" {
  value       = azurerm_user_assigned_identity.umi.id
  description = "The resource id of the user assigned managed identity"
}

output "name" {
  value       = azurerm_user_assigned_identity.umi.name
  description = "The name of the user assigned managed identity"
}

output "principal_id" {
  value       = azurerm_user_assigned_identity.umi.principal_id
  description = "The resource Entra ID object id of the user assigned managed identity"
}


