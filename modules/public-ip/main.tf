resource "azurerm_public_ip" "pip" {
  name                = "${local.public_ip_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = local.public_ip_allocation_method
  sku                 = local.public_ip_sku

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  name                       = "diag-base"
  target_resource_id         = azurerm_public_ip.pip.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "DDoSProtectionNotifications"
  }

  enabled_log {
    category = "DDoSMitigationFlowLogs"
  }

  enabled_log {
    category = "DDoSMitigationReports"
  }

  metric {
    category = "AllMetrics"
  }
}

