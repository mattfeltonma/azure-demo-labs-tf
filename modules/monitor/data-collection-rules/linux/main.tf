resource "azurerm_monitor_data_collection_rule" "rule" {
  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  data_collection_endpoint_id = var.data_collection_endpoint_id
  kind = "Linux"
  description                 = "This data collection rule captures common Linux logs and metrics"

  destinations {
    log_analytics {
      workspace_resource_id = var.law_resource_id
      name                  = var.law_name
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = [var.law_name]
  }
 
  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["Warning"]
      name           = "Linux-Logs"
      streams        = ["Microsoft-Syslog"]
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
