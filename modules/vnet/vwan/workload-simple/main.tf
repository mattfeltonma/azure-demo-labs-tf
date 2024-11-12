## Create virtual network and subnets
##
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.vnet_name}${local.vnet_purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  address_space = [var.address_space_vnet]

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

## Peer the virtual network with a VWAN hub if using VWAN
##
module "vwan_connection" {
  source = "../../../vwan-connection"

  hub_id    = var.vwan_hub_id
  vnet_id   = azurerm_virtual_network.vnet.id
  vnet_name = azurerm_virtual_network.vnet.name

  propagate_default_route = var.vwan_propagate_default_route
  associated_route_table  = var.vwan_associated_route_table
  propagate_route_labels  = var.vwan_propagate_route_labels
  propagate_route_tables  = var.vwan_propagate_route_tables
  inbound_route_map_id    = var.vwan_inbound_route_map_id
  outbound_route_map_id   = var.vwan_outbound_route_map_id
  static_routes           = var.vwan_static_routes
}

## Create route tables
##

module "route_table_app" {
  source              = "../../../route-table"
  purpose             = "app${var.count_index}"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  bgp_route_propagation_enabled = true
  routes                        = []
}

module "route_table_svc" {
  source              = "../../../route-table"
  purpose             = "svc${var.count_index}"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  bgp_route_propagation_enabled = true
  routes                        = []
}

## Create network security groups
##
module "nsg_app" {
  source              = "../../../network-security-group"
  purpose             = "app${var.count_index}"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
    {
      name                       = "AllowSSH"
      description = "Allow SSH from trusted IP"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "2222"
      source_address_prefix      = var.trusted_ip
      destination_address_prefix = "*"
    }
  ]
}

module "nsg_svc" {
  source              = "../../../network-security-group"
  purpose             = "svc${var.count_index}"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
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
    module.nsg_app
  ]

  subnet_id                 = azurerm_subnet.subnet_app.id
  network_security_group_id = module.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_svc" {
  depends_on = [
    azurerm_subnet.subnet_svc,
    module.nsg_svc
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
    module.route_table_app
  ]

  subnet_id      = azurerm_subnet.subnet_app.id
  route_table_id = module.route_table_app.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_svc" {
  depends_on = [
    azurerm_subnet.subnet_svc,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_svc,
    module.route_table_svc
  ]

  subnet_id      = azurerm_subnet.subnet_svc.id
  route_table_id = module.route_table_svc.id
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

  body = jsonencode({
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
  })
  tags = var.tags
}

## Create public IP address for Linux Server
##
module "public_ip_linux" {
  source              = "../../../public-ip"
  purpose             = "linux${var.count_index}"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name

  law_resource_id = var.traffic_analytics_workspace_id
  tags            = var.tags
}

## Creat a Linux web server
##
module "linux_web_server" {
  depends_on = [
    azurerm_subnet_route_table_association.route_table_association_app,
    azurerm_subnet_route_table_association.route_table_association_svc,
    module.vwan_connection,
    module.public_ip_linux
  ]

  source              = "../../../virtual-machine/ubuntu-tools"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name

  purpose        = "web${var.count_index}"
  admin_username = var.admin_username
  admin_password = var.admin_password

  vm_size = var.vm_size_web
  image_reference = {
    publisher = local.image_preference_publisher
    offer     = local.image_preference_offer
    sku       = local.image_preference_sku
    version   = local.image_preference_version
  }

  subnet_id                     = azurerm_subnet.subnet_app.id
  private_ip_address_allocation = "Static"
  nic_private_ip_address        = cidrhost(var.subnet_cidr_app, 20)
  public_ip_address_id          = module.public_ip_linux.id

  law_resource_id = var.traffic_analytics_workspace_id
  dce_id          = var.dce_id
  dcr_id          = var.dcr_id_linux

  tags = var.tags
}
