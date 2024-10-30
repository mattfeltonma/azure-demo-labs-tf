# Create load balancer without public ip frontend and create diagnostic settings
resource "azurerm_lb" "lb" {
    name                = "${local.lb_name}${var.location_code}${var.purpose}${var.random_string}"
    location           = var.location
    resource_group_name = var.resource_group_name
    sku = local.sku
    sku_tier = local.sku_tier

    frontend_ip_configuration {
        name = local.lb_fe_config_name
        zones = [
            1,
            2,
            3
        ]

        # Internal networking configuration
        subnet_id = var.subnet_id
        private_ip_address = var.private_ip_address
        private_ip_address_allocation = local.allocation
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
    depends_on = [ azurerm_monitor_diagnostic_setting.diag-base ]

    name                = local.lb_pool_name
    loadbalancer_id     = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "probe" {
    depends_on = [ azurerm_lb_backend_address_pool.pool ]

    name                = local.lb_probe_name
    loadbalancer_id     = azurerm_lb.lb.id
    protocol            = local.probe_protocol
    port                = local.probe_port
    interval_in_seconds = local.probe_interval
    number_of_probes    = local.probe_number_of_probes
}

## Create the load balancer rule to send all traffic to the backend pool
##
resource "azurerm_lb_rule" "rule" {
    depends_on = [ azurerm_lb_probe.probe ]

    name                = local.lb_rule_name
    loadbalancer_id     = azurerm_lb.lb.id
    frontend_ip_configuration_name = local.lb_fe_config_name
    backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.pool.id
    ]
    probe_id            = azurerm_lb_probe.probe.id
    protocol            = local.rule_protocol
    frontend_port       = local.rule_frontend_port
    backend_port        = local.rule_backend_port
    enable_floating_ip  = local.rule_enable_floating_ip
    idle_timeout_in_minutes = local.rule_idle_timeout_in_minutes
    load_distribution   = local.rule_load_distribution
    disable_outbound_snat = local.rule_disable_outbound_snat
}