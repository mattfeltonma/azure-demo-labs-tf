## Create an Azure OpenAI Service instance
##
resource "azurerm_cognitive_account" "openai" {
  name                = "${local.openai_name}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = local.kind

  custom_subdomain_name = var.custom_subdomain_name
  sku_name = local.sku_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

## Create diagnostic settings
##
resource "azurerm_monitor_diagnostic_setting" "diag" {
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


## Create a deployment for OpenAI's GPT-4o
##
resource "azurerm_cognitive_deployment" "openai_deployment_gpt_4o" {
  depends_on = [
    azurerm_cognitive_account.openai
  ]

  name = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  sku {
    name = "Standard"
    capacity = 20
  }

  model {
    format = "OpenAI"
    name = "gpt-4o"
  }
}

## Create a deployment for OpenAI's ada-002 text embededing model
##
resource "azurerm_cognitive_deployment" "openai_deployment_ada_002" {
  depends_on = [
    azurerm_cognitive_account.openai,
    azurerm_cognitive_deployment.openai_deployment_gpt_4o
  ]

  name = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  sku {
    name = "Standard"
    capacity = 20
  }

  model {
    format = "OpenAI"
    name = "text-embedding-ada-002"
  }
}