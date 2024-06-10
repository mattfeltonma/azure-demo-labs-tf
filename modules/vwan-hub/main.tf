resource "azurerm_virtual_hub" "hub" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  virtual_wan_id         = var.vwan_id
  address_prefix         = var.address_space
  hub_routing_preference = var.routing_preference

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_vpn_gateway" "hub_gw" {
  depends_on = [
    azurerm_virtual_hub.hub
  ]

  count = var.vpn_gateway == true ? 1 : 0

  name                = "vngw${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  bgp_settings {
    asn         = 65515
    peer_weight = 0
  }

  virtual_hub_id = azurerm_virtual_hub.hub.id
  scale_unit     = 1

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-base-vpn-gw" {
  count = var.vpn_gateway == true ? 1 : 0

  name                       = "diag-base"
  target_resource_id         = azurerm_vpn_gateway.hub_gw[0].id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "GatewayDiagnosticLog"
  }

  enabled_log {
    category = "TunnelDiagnosticLog"
  }

  enabled_log {
    category = "RouteDiagnosticLog"
  }

  enabled_log {
    category = "IKEDiagnosticLog"
  }

  metric {
    category = "AllMetrics"
  }
}

