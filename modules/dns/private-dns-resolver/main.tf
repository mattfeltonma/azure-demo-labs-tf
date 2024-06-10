resource "azurerm_private_dns_resolver" "resolver" {
  name                = "${local.private_resolver_name}${local.location_short}${var.random_string}"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = var.vnet_id
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inend" {
  name                    = "${local.private_resolver_inbound_endpoint}${local.location_short}${var.random_string}"
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = var.subnet_id_inbound
  }
  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "outend" {
  name                    = "${local.private_resolver_outbound_endpoint}${local.location_short}${var.random_string}"
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = var.location
  subnet_id               = var.subnet_id_outbound
  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}
