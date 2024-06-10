resource "azurerm_monitor_data_collection_endpoint" "endpoint" {

  name                = "dce${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}