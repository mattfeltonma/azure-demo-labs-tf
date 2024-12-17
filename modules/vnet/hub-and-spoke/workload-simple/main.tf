## Create virtual network and subnets
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
  log_analytics_workspace_id = var.law_resource_id


  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_subnet" "subnet_app" {

  name                              = local.subnet_name_app
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.subnet_cidr_app]
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_svc" {

  name                              = local.subnet_name_svc
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [var.subnet_cidr_svc]
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

## Peer the virtual network with the hub virtual network
##
resource "azurerm_virtual_network_peering" "vnet_peering_to_hub" {
  name                         = "peer-${local.vnet_name}${local.vnet_purpose}${var.location_code}${var.random_string}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.vnet_id_hub
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "vnet_peering_to_spoke" {
  depends_on = [
    azurerm_virtual_network_peering.vnet_peering_to_hub
  ]

  name                         = "peer-hub-to-${local.vnet_name}${local.vnet_purpose}${var.location_code}${var.random_string}"
  resource_group_name          = var.resource_group_name_hub
  virtual_network_name         = var.name_hub
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

## Create route tables
##

module "route_table_app" {
  source              = "../../../route-table"
  purpose             = "app"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  bgp_route_propagation_enabled = false
  routes = [
    {
      name                   = "udr-default"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.fw_private_ip
    }
  ]
}

module "route_table_svc" {
  source              = "../../../route-table"
  purpose             = "svc"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  bgp_route_propagation_enabled = false
  routes = [
  ]
}

## Create network security groups
##
module "nsg_app" {
  source              = "../../../network-security-group"
  purpose             = "app"
  random_string       = var.random_string
  location            = var.location
    location_code = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

module "nsg_svc" {
  source              = "../../../network-security-group"
  purpose             = "svc"
  random_string       = var.random_string
  location            = var.location
    location_code = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

## Associate network security groups with subnets
##
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_app" {
  depends_on = [
    azurerm_subnet.subnet_app,
    module.nsg_app,
    azurerm_virtual_network_peering.vnet_peering_to_spoke
  ]

  subnet_id                 = azurerm_subnet.subnet_app.id
  network_security_group_id = module.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_svc" {
  depends_on = [
    azurerm_subnet.subnet_svc,
    module.nsg_svc,
    azurerm_virtual_network_peering.vnet_peering_to_spoke
  ]

  subnet_id                 = azurerm_subnet.subnet_svc.id
  network_security_group_id = module.nsg_svc.id
}

## Associate route tables with subnets
##
resource "azurerm_subnet_route_table_association" "route_table_association_app" {
  depends_on = [
    azurerm_subnet.subnet_app,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_app,
    module.route_table_app,
    azurerm_virtual_network_peering.vnet_peering_to_hub,
    azurerm_virtual_network_peering.vnet_peering_to_spoke
  ]

  subnet_id      = azurerm_subnet.subnet_app.id
  route_table_id = module.route_table_app.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_svc" {
  depends_on = [
    azurerm_subnet.subnet_svc,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_svc,
    module.route_table_svc,
    azurerm_virtual_network_peering.vnet_peering_to_hub,
    azurerm_virtual_network_peering.vnet_peering_to_spoke
  ]

  subnet_id      = azurerm_subnet.subnet_svc.id
  route_table_id = module.route_table_svc.id
}

## Create a user-assigned managed identity
##
module "managed_identity" {
  source              = "../../../managed-identity"
  purpose             = "wlp"
  random_string       = var.random_string
  location            = var.location
    location_code = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags
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

## Creat a Linux web server
##
module "linux_web_server" {
  depends_on = [ 
    azurerm_subnet_route_table_association.route_table_association_app,
    azurerm_subnet_route_table_association.route_table_association_svc
  ]

  source              = "../../../virtual-machine/ubuntu-tools"
  random_string       = var.random_string
  location            = var.location
  location_code = var.location_code
  resource_group_name = var.resource_group_name

  purpose = "web"
  admin_username = var.admin_username
  admin_password = var.admin_password

  vm_size = var.vm_size_web
  image_reference = {
    publisher = local.image_preference_publisher
    offer     = local.image_preference_offer
    sku       = local.image_preference_sku
    version   = local.image_preference_version
  }

  subnet_id = azurerm_subnet.subnet_app.id
  private_ip_address_allocation = "Static"
  nic_private_ip_address = cidrhost(var.subnet_cidr_app, 20)

  law_resource_id = var.traffic_analytics_workspace_id
  dce_id = var.dce_id
  dcr_id = var.dcr_id_linux

  tags                = var.tags
}
