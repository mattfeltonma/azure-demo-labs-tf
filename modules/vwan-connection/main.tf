resource "azurerm_virtual_hub_connection" "conn" {
  name = var.name

  virtual_hub_id            = var.hub_id
  remote_virtual_network_id = var.vnet_id

  internet_security_enabled = local.propagate_default_route
  routing {
    associated_route_table_id = var.associated_route_table
    propagated_route_table {
      labels          = var.propagate_route_labels
      route_table_ids = var.propagate_route_tables
    }
    inbound_route_map_id  = var.inbound_route_map_id
    outbound_route_map_id = var.outbound_route_map_id

    dynamic "static_vnet_route" {
      for_each = var.static_routes != null ? var.static_routes : []
      content {
        name                = static_vnet_route.value.name
        address_prefixes      = static_vnet_route.value.address_prefixes
        next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
      }
    }
  }
}

