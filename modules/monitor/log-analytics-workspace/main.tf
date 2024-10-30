# Create a Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "law${var.purpose}${var.location_code_primary}${var.random_string}"
  location            = var.location_primary
  resource_group_name = var.resource_group_name_primary

  sku               = local.log_analytics_sku
  retention_in_days = var.retention_in_days

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

# Configure diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  depends_on = [azurerm_log_analytics_workspace.log_analytics_workspace]

  name                       = "diag-base"
  target_resource_id         = azurerm_log_analytics_workspace.log_analytics_workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "SummaryLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

module "data_collection_endpoint_primary" {
  depends_on = [azurerm_monitor_diagnostic_setting.diag-base]

  source = "../data-collection-endpoint"

  purpose             = var.purpose
  resource_group_name = var.resource_group_name_primary
  location            = var.location_primary
  location_code       = var.location_code_primary
  random_string       = var.random_string

  tags = var.tags
}

module "data_collection_endpoint_secondary" {
  count = var.location_code_secondary != null ? 1 : 0

  depends_on = [azurerm_monitor_diagnostic_setting.diag-base]

  source = "../data-collection-endpoint"

  purpose             = var.purpose
  resource_group_name = var.resource_group_name_secondary
  location            = var.location_secondary
  location_code       = var.location_code_secondary
  random_string       = var.random_string

  tags = var.tags
}

module "data_collection_rule_windows" {
  depends_on = [
    module.data_collection_endpoint_primary,
    azurerm_log_analytics_workspace.log_analytics_workspace
 ]

  source = "../data-collection-rules/windows"

  purpose                     = local.data_collection_rule_windows
  resource_group_name         = var.resource_group_name_primary
  location                    = var.location_primary
  data_collection_endpoint_id = module.data_collection_endpoint_primary.id
  law_resource_id             = azurerm_log_analytics_workspace.log_analytics_workspace.id
  law_name                    = azurerm_log_analytics_workspace.log_analytics_workspace.name
  random_string               = var.random_string

  tags = var.tags
}

module "data_collection_rule_linux" {
  depends_on = [
    module.data_collection_endpoint_primary,
    azurerm_log_analytics_workspace.log_analytics_workspace
 ]

  source = "../data-collection-rules/linux"

  purpose                     = local.data_collection_rule_linux
  resource_group_name         = var.resource_group_name_primary
  location                    = var.location_primary
  data_collection_endpoint_id = module.data_collection_endpoint_primary.id
  law_resource_id             = azurerm_log_analytics_workspace.log_analytics_workspace.id
  law_name                    = azurerm_log_analytics_workspace.log_analytics_workspace.name
  random_string               = var.random_string

  tags = var.tags
}
