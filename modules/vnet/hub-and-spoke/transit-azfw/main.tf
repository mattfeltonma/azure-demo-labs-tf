## Create transit virtual network
##

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.vnet_name}${local.vnet_purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  address_space = [var.address_space_vnet]
  dns_servers   = var.dns_servers

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  name                       = "diag-base"
  target_resource_id         = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id = var.traffic_analytics_workspace_id


  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
  }
}

## Create the flow log and enable traffic analytics
##
resource "azapi_resource" "vnet_flow_log" {
  depends_on = [
    azurerm_virtual_network.vnet
  ]

  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = "${local.flow_logs_name}${local.vnet_purpose}${var.location_code}${var.random_string}"
  location  = var.location
  parent_id = var.network_watcher_resource_id

  body = {
    properties = {
      enabled = local.flow_logs_enabled
      format = {
        type    = "JSON"
        version = 2
      }

      retentionPolicy = {
        enabled = local.flow_logs_retention_policy_enabled
        days    = local.flow_logs_retention_days
      }

      storageId        = var.storage_account_id_flow_logs
      targetResourceId = azurerm_virtual_network.vnet.id

      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = local.traffic_analytics_enabled
          trafficAnalyticsInterval = local.traffic_analytics_interval_in_minutes
          workspaceId              = var.traffic_analytics_workspace_guid
          workspaceRegion          = var.traffic_analytics_workspace_location
          workspaceResourceId      = var.traffic_analytics_workspace_id
        }
      }
    }
  }
  tags = var.tags
}

resource "azurerm_subnet" "subnet_gateway" {
  depends_on = [
    azapi_resource.vnet_flow_log,
    azurerm_virtual_network.vnet
  ]

  name                              = local.subnet_name_gateway
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.subnet_cidr_gateway]
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_firewall" {

  depends_on = [
    azurerm_subnet.subnet_gateway
  ]

  name                              = local.subnet_name_firewall
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.subnet_cidr_firewall]
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

## Create a virtual network gateway
##
module "gateway" {
  source              = "../../../virtual-network-gateway"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name

  purpose           = "cnt"
  subnet_id_gateway = azurerm_subnet.subnet_gateway.id
  law_resource_id   = var.traffic_analytics_workspace_id

  tags = var.tags
}

## Create the Azure Firewall instance
##
module "firewall" {
  source              = "../../../firewall"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name

  firewall_subnet_id       = azurerm_subnet.subnet_firewall.id
  dns_servers              = var.dns_servers
  dns_cidr                 = var.subnet_cidr_dns
  address_space_apim       = var.address_space_apim
  address_space_azure      = var.address_space_azure
  address_space_onpremises = var.address_space_onpremises

  law_resource_id      = var.traffic_analytics_workspace_id
  law_workspace_region = var.traffic_analytics_workspace_location

  tags = var.tags
}

## Create route tables
##
module "route_table_gateway" {
  depends_on = [
    module.gateway
  ]

  source              = "../../../route-table"
  purpose             = "vgw"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  bgp_route_propagation_enabled = true
  routes = [
    {
      name                   = "udr-ss"
      address_prefix         = var.vnet_cidr_ss
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip
    },
    {
      name                   = "udr-wl"
      address_prefix         = var.vnet_cidr_wl
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.private_ip
    }
  ]
}

module "route_table_azfw" {
  depends_on = [
    module.firewall
  ]

  source              = "../../../route-table"
  purpose             = "fw"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  bgp_route_propagation_enabled = true
  routes = [
    {
      name                   = "udrdef"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "Internet"
    }
  ]
}


## Associate route tables with subnets
##
resource "azurerm_subnet_route_table_association" "route_table_association_gateway" {
  depends_on = [
    module.route_table_gateway
  ]

  subnet_id      = azurerm_subnet.subnet_gateway.id
  route_table_id = module.route_table_gateway.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_azfw" {
  depends_on = [
    module.route_table_azfw
  ]

  subnet_id      = azurerm_subnet.subnet_firewall.id
  route_table_id = module.route_table_azfw.id
}

## Set the DNS server settings to the Azure Firewall instance
##
resource "azurerm_virtual_network_dns_servers" "vnet_dns_servers" {
  depends_on = [
    module.gateway,
    module.firewall,
    azapi_resource.vnet_flow_log,
    azurerm_virtual_network.vnet
  ]

  virtual_network_id = azurerm_virtual_network.vnet.id
  dns_servers        = [module.firewall.private_ip]
}


