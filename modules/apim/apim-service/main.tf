## Create a public IP address
##
module "public-ip" {
  source = "../../public-ip"

  location            = var.location
  resource_group_name = var.resource_group_name
  purpose             = var.purpose
  location_code       = var.location_code
  random_string       = var.random_string
  dns_label           = var.dns_label
  law_resource_id     = var.law_resource_id
  tags                = var.tags
}

## Create an Azure API Management service instance
##
resource "azurerm_api_management" "apim" {
  depends_on = [
    module.public-ip 
 ]
  name                = "${local.apim_name_prefix}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = local.sku_name

  public_ip_address_id = module.public-ip.id
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = var.subnet_id
  }

  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

## Pause for 60 seconds after API Management instance is created to allow for system-managed identity to replicate
##
resource "time_sleep" "sleep_rbac" {
  depends_on = [
    azurerm_api_management.apim
]
  create_duration = "60s"
}

## Create Azure RBAC Role Assignment for API Management instance
##
resource "azurerm_role_assignment" "apim_rbac" {
  depends_on = [ 
    time_sleep.sleep_rbac
 ]
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_api_management.apim.identity[0].principal_id
}

## Create a diagnostic setting to send logs to Log Analytics
##
resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  name                       = "diag-base"
  target_resource_id         = azurerm_api_management.apim.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "GatewayLogs"
  }

  enabled_log {
    category = "WebSocketConnectionLogs"
  }

  enabled_log {
    category = "DeveloperPortalAuditLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

