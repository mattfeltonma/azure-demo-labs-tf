output "id" {
  value       = azapi_resource.search.id
  description = "The resource id of the AI Search instance"
}

output "managed_identity_principal_id" {
  value       = azapi_resource.search.output.identity.principalId
  description = "The principal id of the managed identity of the AI Search instance"
}

output "name" {
  value       = azapi_resource.search.name
  description = "The name of the AI Search instance"
}

