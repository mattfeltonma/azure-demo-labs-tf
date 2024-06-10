output "dce_id" {
  value       = module.data_collection_endpoint.id
  description = "The resource id of the data collection endpoint"
}

output "dcr_id_windows" {
  value       = module.data_collection_rule_windows.id
  description = "The resource id of the Data Collection Rule for Windows"
}

output "dcr_id_linux" {
  value       = module.data_collection_rule_linux.id
  description = "The resource id of the Data Collection Rule for Linux"
}

output "name" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.name
  description = "The name of the log analytics workspace"
}

output "id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  description = "The resource id of the log analytics workspace"
}

output "location" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.location
  description = "The region of the log analytics workspace"
}

output "workspace_id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
  description = "The workspace id"
}