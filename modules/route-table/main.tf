resource "azurerm_route_table" "route_table" {
  name                = "${local.route_table_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  disable_bgp_route_propagation = var.disable_bgp_route_propagation

  dynamic "route" { 
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = contains(keys(route.value), "next_hop_in_ip_address") ? route.value.next_hop_in_ip_address : null
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
