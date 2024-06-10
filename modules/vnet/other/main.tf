resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  address_space = var.address_space_vnet
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

resource "azurerm_subnet" "subnet_dnsin" {

  name                                          = var.subnet_name_dnsin
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = var.subnet_cidr_dnsin
  private_endpoint_network_policies_enabled     = local.enable_private_endpoint_network_policies
  private_link_service_network_policies_enabled = local.enable_private_link_service_network_policies
}

resource "azurerm_subnet" "subnet_dnsout" {

  name                                          = var.subnet_name_dnsout
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = var.subnet_cidr_dnsout
  private_endpoint_network_policies_enabled     = local.enable_private_endpoint_network_policies
  private_link_service_network_policies_enabled = local.enable_private_link_service_network_policies
}

resource "azurerm_subnet" "subnet_pe" {

  name                                          = var.subnet_name_pe
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = var.subnet_cidr_pe
  private_endpoint_network_policies_enabled     = local.enable_private_endpoint_network_policies
  private_link_service_network_policies_enabled = local.enable_private_link_service_network_policies
}

resource "azurerm_subnet" "subnet_tools" {

  name                                          = var.subnet_name_tools
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = var.subnet_cidr_tools
  private_endpoint_network_policies_enabled     = local.enable_private_endpoint_network_policies
  private_link_service_network_policies_enabled = local.enable_private_link_service_network_policies
}

module "route_table_app" {

  source              = "../../route-table"
  name                = "rt-app-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  routes = []
}

module "route_table_dnsin" {

  source              = "../../route-table"
  name                = "rt-data-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags


  routes = []

}

module "route_table_dnsin" {

  source              = "../../route-table"
  name                = "rt-data-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags


  routes = []

}

module "route_table_dnsin" {

  source              = "../../route-table"
  name                = "rt-data-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags


  routes = []

}

module "nsg_app" {
  source              = "../../network-security-group"
  name                = "nsg-app-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id                     = var.law_resource_id
  network_watcher_name                = var.network_watcher_name
  network_watcher_resource_group_name = var.network_watcher_resource_group_name
  trafficAnalyticsWorkspaceId         = var.law_resource_id
  trafficAnalyticsWorkspaceGuid       = var.law_workspace_id
  trafficAnalyticsWorkspaceRegion     = var.law_workspace_region
  flowLogStorageAccountId             = var.storage_account_id_flow_logs
  security_rules = [
    {
      name                       = "allow-ssh"
      description                = "Allow SSH from trusted IP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.ip_trusted
      destination_address_prefix = "*"
    }
  ]
}

module "nsg_data" {
  source              = "../../network-security-group"
  name                = "nsg-data-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id                     = var.law_resource_id
  network_watcher_name                = var.network_watcher_name
  network_watcher_resource_group_name = var.network_watcher_resource_group_name
  trafficAnalyticsWorkspaceId         = var.law_resource_id
  trafficAnalyticsWorkspaceGuid       = var.law_workspace_id
  trafficAnalyticsWorkspaceRegion     = var.law_workspace_region
  flowLogStorageAccountId             = var.storage_account_id_flow_logs
  security_rules = [
  ]
}

module "nsg_pe" {
  source              = "../../network-security-group"
  name                = "nsg-pe-r${var.region_number}-w${var.workload_number}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id                     = var.law_resource_id
  network_watcher_name                = var.network_watcher_name
  network_watcher_resource_group_name = var.network_watcher_resource_group_name
  trafficAnalyticsWorkspaceId         = var.law_resource_id
  trafficAnalyticsWorkspaceGuid       = var.law_workspace_id
  trafficAnalyticsWorkspaceRegion     = var.law_workspace_region
  flowLogStorageAccountId             = var.storage_account_id_flow_logs
  security_rules = [
  ]
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_app" {
  depends_on = [
    azurerm_subnet.subnet_app,
    module.nsg_app
  ]

  subnet_id                 = azurerm_subnet.subnet_app.id
  network_security_group_id = module.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_data" {
  depends_on = [ 
    azurerm_subnet.subnet_data,
    module.nsg_data
  ]

  subnet_id                 = azurerm_subnet.subnet_data.id
  network_security_group_id = module.nsg_data.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_pe" {
  depends_on = [
    azurerm_subnet.subnet_pe,
    module.nsg_pe
  ]
  subnet_id                 = azurerm_subnet.subnet_pe.id
  network_security_group_id = module.nsg_pe.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_app" {
  depends_on = [
    azurerm_subnet.subnet_app,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_app,
    module.route_table_app
  ]

  subnet_id      = azurerm_subnet.subnet_app.id
  route_table_id = module.route_table_app.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_data" {
  depends_on = [
    azurerm_subnet.subnet_app,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_data,
    module.route_table_data
  ]

  subnet_id      = azurerm_subnet.subnet_data.id
  route_table_id = module.route_table_data.id
}
