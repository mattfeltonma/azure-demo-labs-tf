module "public-ip" {

  count               = 2
  source              = "../../modules/public-ip"
  random_string       = var.random_string
  location            = var.location
    location_code       = var.location_code
  resource_group_name = var.resource_group_name

  purpose         = "vpn${count.index + 1}"
  law_resource_id = var.law_resource_id

  tags = var.tags

}



resource "azurerm_virtual_network_gateway" "vgw" {
  depends_on = [
    module.public-ip
  ]

  name                = "${local.vng_name}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = local.vng_type
  vpn_type            = local.vpn_type
  sku                 = var.sku

  active_active = true
  enable_bgp    = true

  ip_configuration {
    name                          = "ipconfig-1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = module.public-ip[0].id
    subnet_id                     = var.subnet_id_gateway
  }

  ip_configuration {
    name                          = "ipconfig-2"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = module.public-ip[1].id
    subnet_id                     = var.subnet_id_gateway
  }

  bgp_settings {
    asn = 65515
    peering_addresses {
      ip_configuration_name = "ipconfig-1"
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

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  name                       = "diag-base"
  target_resource_id         = azurerm_virtual_network_gateway.vgw.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "GatewayDiagnosticLog"
  }

  enabled_log {
    category = "IKEDiagnosticLog"
  }

  enabled_log {
    category = "P2SDiagnosticLog"
  }

  enabled_log {
    category = "RouteDiagnosticLog"
  }

  enabled_log {
    category = "TunnelDiagnosticLog"
  }

  metric {
    category = "AllMetrics"
  }
}
