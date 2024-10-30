resource "azurerm_user_assigned_identity" "umi" {
  location            = var.location
  name                = "${local.umi_name}${var.purpose}${var.location_code}${var.random_string}"
  resource_group_name = var.resource_group_name

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}



