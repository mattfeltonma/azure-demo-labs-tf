output "name" {
  value       = azurerm_cognitive_account.openai.name
  description = "The name of the Azure OpenAI Service instance"
}

output "id" {
  value       = azurerm_cognitive_account.openai.id
  description = "The id of the Azure OpenAI Service instance"
}

output "endpoint" {
  value       = azurerm_cognitive_account.openai.endpoint
  description = "The endpoint of the Azure OpenAI Service instance"
}

output "managed_identity_principal_id" {
  value       = azurerm_cognitive_account.openai.identity.0.principal_id
  description = "The principal id of the managed identity of the Azure OpenAI Service instance"
}