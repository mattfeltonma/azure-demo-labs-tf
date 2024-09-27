output "name" {
  value       = azurerm_cognitive_account.openai.name
  description = "The name of the Azure OpenAI Service instance"
}

output "id" {
  value       = azurerm_cognitive_account.openai.id
  description = "The id of the Azure OpenAI Service instance"
}