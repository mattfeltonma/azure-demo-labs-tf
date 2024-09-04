resource "azurerm_private_endpoint" "pe" {
  name                = "${local.pe_name}${var.resource_name}${var.subresource_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  custom_network_interface_name = "${local.pe_nic_name}${var.resource_name}${var.subresource_name}"

  private_service_connection {
    name                           = "${local.pe_conn_name}${var.resource_name}${var.subresource_name}"
    private_connection_resource_id = var.resource_id
    subresource_names = [var.subresource_name]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.pe_zone_group_conn_name}${var.resource_name}"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}