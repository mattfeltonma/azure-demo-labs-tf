resource "azapi_resource" "search" {
  type                      = "Microsoft.Search/searchServices@2024-03-01-preview"
  name                      = "${local.ai_search_prefix}${var.purpose}${var.location_code}${var.random_string}"
  parent_id                 = var.resource_group_id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    identity = {
      type = "SystemAssigned"
    }
    sku = {
      name = local.sku
    }

    properties = {
      disableLocalAuth = true

      hostingMode       = "default"
      partitionCount    = 1
      replicaCount      = 1
      semanticSearch = "standard"

      publicNetworkAccess = "disabled"
      networkRuleSet = {
        bypass = "AzureServices"
      }
    }
    tags = var.tags
  }

  response_export_values = [
    "identity.principalId"
  ]
  
  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  depends_on = [
    azapi_resource.search
  ]

  name                       = "diag-base"
  target_resource_id         = azapi_resource.search.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "OperationLogs"
  }
  metric {
    category = "AllMetrics"
  }
}
