## Create public IP for external load balancer
##
module "public-ip" {
  source              = "../../../modules/public-ip"
  random_string       = var.random_string
  purpose             = var.purpose
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name

  law_resource_id = var.law_resource_id

  tags = var.tags
}

## Create load balancer with public ip frontend and create diagnostic settings
##
resource "azurerm_lb" "lb" {
  depends_on = [
    module.public-ip
  ]
  name                = "${local.lb_name}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = local.sku
  sku_tier            = local.sku_tier

  frontend_ip_configuration {
    name = local.lb_fe_config_name

    # External networking configuration
    public_ip_address_id = module.public-ip.id
  }

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  name                       = "diag-base"
  target_resource_id         = azurerm_lb.lb.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "LoadBalancerHealthEvent"
  }

  metric {
    category = "AllMetrics"
  }
}

## Create the backend pool and probe
##
resource "azurerm_lb_backend_address_pool" "pool" {
  depends_on = [azurerm_monitor_diagnostic_setting.diag-base]

  name            = local.lb_pool_name
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "probe" {
  depends_on = [azurerm_lb_backend_address_pool.pool]

  name                = local.lb_probe_name
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = local.probe_protocol
  port                = local.probe_port
  interval_in_seconds = local.probe_interval
  number_of_probes    = local.probe_number_of_probes
}
