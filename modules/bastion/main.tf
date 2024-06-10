module "public-ip" {
  source              = "../../modules/public-ip"
  random_string       = var.random_string
  purpose             = "bst"
  location            = var.location
  resource_group_name = var.resource_group_name

  law_resource_id = var.law_resource_id

  tags = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${local.bastion_name}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "config"
    subnet_id            = var.subnet_id
    public_ip_address_id = module.public-ip.id
  }

  sku = var.sku
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
  target_resource_id         = azurerm_bastion_host.bastion.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "BastionAuditLogs"
  }
  metric {
    category = "AllMetrics"
  }
}