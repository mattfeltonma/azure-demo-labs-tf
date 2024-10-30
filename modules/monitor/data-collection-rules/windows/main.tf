resource "azurerm_monitor_data_collection_rule" "rule" {
  name                        = "${local.data_collection_rule_prefix}${var.purpose}${var.random_string}"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  kind                        = "Windows"
  description                 = "This data collection rule captures common Windows logs and metrics"
  data_collection_endpoint_id = var.data_collection_endpoint_id

  destinations {
    log_analytics {
      workspace_resource_id = var.law_resource_id
      name                  = var.law_name
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = [var.law_name]
  }

  data_sources {
    windows_event_log {
      name    = "Windows-Event-Logs"
      streams = ["Microsoft-WindowsEvent"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        "Directory Services!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=5)]]"
      ]
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}
