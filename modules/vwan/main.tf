resource "azurerm_virtual_wan" "vwan" {
    name = "${local.vwan_name}${var.location_code}${var.random_string}"

    resource_group_name = var.resource_group_name
    location = var.location

    allow_branch_to_branch_traffic = var.allow-branch
    type = local.sku

    tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}