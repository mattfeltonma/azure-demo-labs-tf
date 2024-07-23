## Create virtual network
##
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.vnet_name}${local.vnet_purpose}${local.location_short}${var.random_string}"
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

resource "azurerm_subnet" "subnet_agw" {

  name                              = local.subnet_name_agw
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_agw
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_apim" {

  name                              = local.subnet_name_apim
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_apim
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_app" {

  name                              = local.subnet_name_app
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_app
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_data" {

  name                              = local.subnet_name_data
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_data
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_mgmt" {

  name                              = local.subnet_name_mgmt
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_mgmt
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_svc" {

  name                              = local.subnet_name_svc
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_svc
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_tool" {

  name                              = local.subnet_name_tool
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_tool
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

resource "azurerm_subnet" "subnet_vint" {

  name                              = local.subnet_name_vint
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.subnet_cidr_vint
  private_endpoint_network_policies = local.private_endpoint_network_policies
}

## Create route tables
##

module "route_table_agw" {
  source              = "../../route-table"
  purpose             = "agw"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
    {
      name           = "udr-default"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

module "route_table_apim" {
  source              = "../../route-table"
  purpose             = "apim"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
    {
      name           = "udr-api-management"
      address_prefix = "ApiManagement"
      next_hop_type  = "Internet"
    }
  ]
}

module "route_table_app" {
  source              = "../../route-table"
  purpose             = "app"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
  ]
}

module "route_table_data" {
  source              = "../../route-table"
  purpose             = "data"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
  ]
}

module "route_table_mgmt" {
  source              = "../../route-table"
  purpose             = "mgmt"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
  ]
}

module "route_table_svc" {
  source              = "../../route-table"
  purpose             = "svc"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
  ]
}

module "route_table_tool" {
  source              = "../../route-table"
  purpose             = "tool"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
  ]
}

module "route_table_vint" {
  source              = "../../route-table"
  purpose             = "vint"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  disable_bgp_route_propagation = true
  routes = [
  ]
}

## Create network security groups
##

module "nsg_agw" {
  source              = "../../network-security-group"
  purpose             = "agw"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
    {
      name                       = "AllowHttpInboundFromInternet"
      description                = "Allow inbound HTTP to Application Gateway Internet"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 80
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHttpsInboundFromInternet"
      description                = "Allow inbound HTTPS to Application Gateway Internet"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 443
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                    = "AllowHttpHttpsInboundFromIntranet"
      description             = "Allow inbound HTTP/HTTPS to Application Gateway from Intranet"
      priority                = 1020
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = [80, 443]
      source_address_prefixes = [
        "192.168.0.0/16",
        "172.16.0.0/12",
        "10.0.0.0/8"
      ]
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowGatewayManagerInbound"
      description                = "Allow inbound Application Gateway Manager Traffic"
      priority                   = 1030
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowAzureLoadBalancerInbound"
      description                = "Allow inbound traffic from Azure Load Balancer to support probes"
      priority                   = 1040
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyAllInbound"
      description                = "Deny all inbound traffic"
      priority                   = 2000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowAllOutbound"
      description                = "Allow Application Gateway all outbound traffic"
      priority                   = 1130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      name                       = "DenyAllOutbound"
      description                = "Deny all outbound traffic"
      priority                   = 2100
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

module "nsg_apim" {
  source              = "../../network-security-group"
  purpose             = "apim"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
    {
      name                   = "AllowHttpsInboundFromRfc1918"
      description            = "Allow inbound HTTP from RFC1918"
      priority               = 1000
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_port_range      = "*"
      destination_port_range = 443
      source_address_prefixes = [
        "192.168.0.0/16",
        "172.16.0.0/12",
        "10.0.0.0/8"
      ]
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowApiManagementManagerService"
      description                = "Allow inbound management of API Management instancest"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 3443
      source_address_prefix      = "ApiManagement"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAzureLoadBalancerInbound"
      description                = "Allow inbound traffic from Azure Load Balancer to support probes"
      priority                   = 1020
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 6390
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowApiManagementSyncCachePolicies"
      description                = "Allow instances within API Management Service to sync cache policies"
      priority                   = 1030
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_range     = 4290
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name              = "AllowApiManagementSyncRateLimits"
      description       = "Allow instances within API Management Service to sync rate limits"
      priority          = 1040
      direction         = "Inbound"
      access            = "Allow"
      protocol          = "Udp"
      source_port_range = "*"
      destination_port_ranges = [
        "6380",
        "6381-6383"
      ]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "DenyAllInbound"
      description                = "Deny all inbound traffic"
      priority                   = 2000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

module "nsg_app" {
  source              = "../../network-security-group"
  purpose             = "app"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

module "nsg_data" {
  source              = "../../network-security-group"
  purpose             = "data"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

module "nsg_mgmt" {
  source              = "../../network-security-group"
  purpose             = "mgmt"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

module "nsg_svc" {
  source              = "../../network-security-group"
  purpose             = "svc"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

module "nsg_tool" {
  source              = "../../network-security-group"
  purpose             = "tool"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

module "nsg_vint" {
  source              = "../../network-security-group"
  purpose             = "vint"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id = var.law_resource_id
  security_rules = [
  ]
}

## Associate network security groups with subnets
##
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_agw" {
  depends_on = [
    azurerm_subnet.subnet_agw,
    module.nsg_agw
  ]

  subnet_id                 = azurerm_subnet.subnet_agw.id
  network_security_group_id = module.nsg_agw.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_apim" {
  depends_on = [
    azurerm_subnet.subnet_apim,
    module.nsg_apim
  ]

  subnet_id                 = azurerm_subnet.subnet_apim.id
  network_security_group_id = module.nsg_apim.id
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

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_mgmt" {
  depends_on = [
    azurerm_subnet.subnet_mgmt,
    module.nsg_mgmt
  ]

  subnet_id                 = azurerm_subnet.subnet_mgmt.id
  network_security_group_id = module.nsg_mgmt.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_svc" {
  depends_on = [
    azurerm_subnet.subnet_svc,
    module.nsg_svc
  ]

  subnet_id                 = azurerm_subnet.subnet_svc.id
  network_security_group_id = module.nsg_svc.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_tool" {
  depends_on = [
    azurerm_subnet.subnet_tool,
    module.nsg_tool
  ]

  subnet_id                 = azurerm_subnet.subnet_tool.id
  network_security_group_id = module.nsg_tool.id
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_vint" {
  depends_on = [
    azurerm_subnet.subnet_vint,
    module.nsg_vint
  ]

  subnet_id                 = azurerm_subnet.subnet_vint.id
  network_security_group_id = module.nsg_vint.id
}

## Associate route tables with subnets
##
resource "azurerm_subnet_route_table_association" "route_table_association_agw" {
  depends_on = [
    azurerm_subnet.subnet_agw,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_agw,
    module.route_table_agw
  ]

  subnet_id      = azurerm_subnet.subnet_agw.id
  route_table_id = module.route_table_agw.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_apim" {
  depends_on = [
    azurerm_subnet.subnet_apim,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_apim,
    module.route_table_apim
  ]

  subnet_id      = azurerm_subnet.subnet_apim.id
  route_table_id = module.route_table_apim.id
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
    azurerm_subnet.subnet_data,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_data,
    module.route_table_data
  ]

  subnet_id      = azurerm_subnet.subnet_data.id
  route_table_id = module.route_table_data.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_mgmt" {
  depends_on = [
    azurerm_subnet.subnet_mgmt,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_mgmt,
    module.route_table_mgmt
  ]

  subnet_id      = azurerm_subnet.subnet_mgmt.id
  route_table_id = module.route_table_mgmt.id
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

resource "azurerm_subnet_route_table_association" "route_table_association_tool" {
  depends_on = [
    azurerm_subnet.subnet_tool,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_tool,
    module.route_table_tool
  ]

  subnet_id      = azurerm_subnet.subnet_tool.id
  route_table_id = module.route_table_tool.id
}

resource "azurerm_subnet_route_table_association" "route_table_association_vint" {
  depends_on = [
    azurerm_subnet.subnet_vint,
    azurerm_subnet_network_security_group_association.subnet_nsg_association_vint,
    module.route_table_vint
  ]

  subnet_id      = azurerm_subnet.subnet_vint.id
  route_table_id = module.route_table_vint.id
}

## Create a user-assigned managed identity
##
module "managed_identity" {
  source              = "../../managed-identity"
  purpose             = "wlp"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

## Create Private DNS Zones and Virtual Network Links
##
module "private_dns_zones" {
  depends_on = [
    azurerm_virtual_network.vnet
  ]

  source              = "../../dns/private-dns-zone"
  resource_group_name = var.resource_group_name

  for_each = {
    for zone in var.private_dns_namespaces :
    zone => zone
  }

  name    = each.value
  vnet_id = azurerm_virtual_network.vnet.id

  tags = var.tags
}

## Create a Key Vault instance
##
module "key_vault" {
  depends_on = [
    module.managed_identity,
    module.private_dns_zones
  ]

  source              = "../../key-vault"
  purpose             = "wlp"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  law_resource_id    = var.law_resource_id
  kv_admin_object_id = module.managed_identity.principal_id
}

## Create a Private Endpoint for the Key Vault
##
module "private_endpoint_kv" {
  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  resource_name     = module.key_vault.name
  resource_id       = module.key_vault.id
  subresource_names = ["vault"]


  subnet_id = azurerm_subnet.subnet_svc.id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}

## Create the flow log and enable traffic analytics
##
resource "azapi_resource" "vnet_flow_log" {
  depends_on = [
    azurerm_virtual_network.vnet
  ]

  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = "${local.flow_logs_name}${local.vnet_purpose}${local.location_short}${var.random_string}"
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

## Deploy Windows Tool server
##
module "windows_vm_tool" {
  depends_on = [
    azapi_resource.vnet_flow_log
  ]

  source              = "../../virtual-machine/windows-tools"
  purpose             = "too"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = var.resource_group_name

  admin_username = var.admin_username
  admin_password = var.admin_password

  vm_size = var.sku_tools_size
  image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.sku_tools_os
    version   = "latest"
  }
  subnet_id = azurerm_subnet.subnet_tool.id

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_win_tools" {
  depends_on = [
    module.windows_vm_tool
  ]
  name                    = "${local.dcr_association}${module.windows_vm_tool.name}"
  description             = "Data Collection Rule Association for Windows Tools VM"
  data_collection_rule_id = var.dcr_id_windows
  target_resource_id      = module.windows_vm_tool.id
}

resource "azurerm_monitor_data_collection_rule_association" "dcea_win_tools" {
  target_resource_id          = module.windows_vm_tool.id
  data_collection_endpoint_id = var.dce_id
  description                 = "Data Collection Endpoint Association for Windows Tools VM"
}
