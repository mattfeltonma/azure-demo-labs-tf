## Create an Azure OpenAI Service instance
##
resource "azurerm_cognitive_account" "openai" {
  name                = "${local.openai_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = local.kind

  custom_subdomain_name = var.custom_subdomain_name
  sku_name = local.sku_name

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

## Create a deployment for OpenAI's GPT-4o
##
resource "azurerm_cognitive_account_deployment" "openai_deployment" {
  account_id = azurerm_cognitive_account.openai.id
  name       = "gpt-4o"
  location   = var.location
}

## Create diagnostic settings
##
resource "azurerm_monitor_diagnostic_setting" "diag" {

  depends_on = [azurerm_cognitive_account.openai]

  name                       = "diag"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Trace"
  }

  metric {
    category = "AllMetrics"
  }
}
