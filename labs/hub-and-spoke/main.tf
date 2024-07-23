# Create a random string
#
resource "random_string" "unique" {
  length      = 3
  min_numeric = 3
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

# Create resource groups
#
resource "azurerm_resource_group" "rgtran" {

  name     = "rgtran${local.location_short}${random_string.unique.result}"
  location = var.location

  tags = local.tags
}

resource "azurerm_resource_group" "rgshared" {

  name     = "rgshared${local.location_short}${random_string.unique.result}"
  location = var.location

  tags = local.tags
}

resource "azurerm_resource_group" "rgwork" {

  name     = "rgwork${local.location_short}${random_string.unique.result}"
  location = var.location

  tags = local.tags
}

# Grant the Terraform identity access to Key Vault secrets, certificates, and keys all Key Vaults
#
resource "azurerm_role_assignment" "assign-tf" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgshared.name}${data.azurerm_client_config.identity_config.object_id}")
  scope                = azurerm_resource_group.rgshared.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.identity_config.object_id
}

# Create Log Analytics Workspace
#
module "law" {
  depends_on = [
    azurerm_resource_group.rgshared
  ]

  source              = "../../modules/monitor/log-analytics-workspace"
  random_string       = random_string.unique.result
  purpose             = "cnt"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgshared.name
  tags                = local.tags
}

# Create Storage Account for Flow Logs
#
module "storage_account_flow_logs" {
  depends_on = [
    azurerm_resource_group.rgshared,
    module.law
  ]

  source              = "../../modules/storage-account"
  purpose             = "flv"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgshared.name
  tags                = local.tags

  law_resource_id = module.law.id
}

# Create a transit services virtual network
##
module "transit-vnet" {
  depends_on = [
    azurerm_resource_group.rgtran,
    module.law,
    module.storage_account_flow_logs
  ]

  source              = "../../modules/vnet/transit"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgtran.name

  address_space_vnet   = [var.vnet_cidr_tr]
  subnet_cidr_gateway  = [cidrsubnet(var.vnet_cidr_tr, 8, 0)]
  subnet_cidr_firewall = [cidrsubnet(var.vnet_cidr_tr, 8, 1)]
  subnet_cidr_dns      = cidrsubnet(var.vnet_cidr_ss, 8, 1)

  address_space_onpremises = var.address_space_onpremises
  address_space_azure      = var.address_space_azure
  vnet_cidr_ss             = var.vnet_cidr_ss
  vnet_cidr_wl             = var.vnet_cidr_wl

  network_watcher_resource_id          = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.network_watcher_resource_group_name}/providers/Microsoft.Network/networkWatchers/${var.network_watcher_name}${var.location}"
  storage_account_id_flow_logs         = module.storage_account_flow_logs.id
  traffic_analytics_workspace_guid     = module.law.workspace_id
  traffic_analytics_workspace_id       = module.law.id
  traffic_analytics_workspace_location = module.law.location

  tags = local.tags
}

## Create a shared services virtual network
##
module "shared-vnet" {
  depends_on = [
    azurerm_resource_group.rgshared,
    module.transit-vnet
  ]

  source              = "../../modules/vnet/shared"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgshared.name

  address_space_vnet  = [var.vnet_cidr_ss]
  subnet_cidr_bastion = [cidrsubnet(var.vnet_cidr_ss, 8, 0)]
  subnet_cidr_dnsin   = [cidrsubnet(var.vnet_cidr_ss, 8, 1)]
  subnet_cidr_dnsout  = [cidrsubnet(var.vnet_cidr_ss, 8, 2)]
  subnet_cidr_tools   = [cidrsubnet(var.vnet_cidr_ss, 8, 3)]
  subnet_cidr_pe      = [cidrsubnet(var.vnet_cidr_ss, 8, 4)]
  fw_private_ip       = module.transit-vnet.azfw_private_ip
  dns_servers = [
    module.transit-vnet.azfw_private_ip
  ]
  name_hub = module.transit-vnet.name
  resource_group_name_hub = azurerm_resource_group.rgtran.name
  vnet_id_hub = module.transit-vnet.id

  law_resource_id      = module.law.id
  law_workspace_id     = module.law.workspace_id
  law_workspace_region = module.law.location
  dce_id = module.law.dce_id
  dcr_id_windows = module.law.dcr_id_windows

  storage_account_id_flow_logs         = module.storage_account_flow_logs.id
  network_watcher_resource_id          = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.network_watcher_resource_group_name}/providers/Microsoft.Network/networkWatchers/${var.network_watcher_name}${var.location}"
  traffic_analytics_workspace_guid     = module.law.workspace_id
  traffic_analytics_workspace_id       = module.law.id
  traffic_analytics_workspace_location = module.law.location

  sku_tools_size = var.sku_tools_size
  sku_tools_os   = var.sku_tools_os
  admin_username = var.admin_username
  admin_password = var.admin_password

  tags = local.tags
}

## Create centralized Azure Key Vault
##
module "central-keyvault" {
  depends_on = [
    azurerm_resource_group.rgshared
  ]

  source              = "../../modules/key-vault"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgshared.name
  purpose             = "cnt"
  law_resource_id     = module.law.id
  kv_admin_object_id  = var.key_vault_admin

  tags = local.tags
}

## Add virtual machine user and password to Azure Key Vault
##
resource "azurerm_key_vault_secret" "vm-credentials" {
  depends_on = [
    module.central-keyvault
  ]
  name         = "vm-credentials"
  value        = jsonencode({
    admin_username = var.admin_username
    admin_password = var.admin_password
  })
  key_vault_id = module.central-keyvault.id
}

## Create Private DNS Zones and Virtual Network Links
##
module "private_dns_zones" {
  depends_on = [
    azurerm_resource_group.rgshared,
    module.shared-vnet
  ]

  source              = "../../modules/dns/private-dns-zone"
  resource_group_name = azurerm_resource_group.rgshared.name

  for_each = {
    for zone in var.private_dns_namespaces :
    zone => zone
  }

  name    = each.value
  vnet_id = module.shared-vnet.id

  tags = local.tags
}

## Modify the DNS Server settings of the Azure Firewall Policy
##
resource "null_resource" "update-policy-dns" {
  depends_on = [
    module.private_dns_zones
  ]
  provisioner "local-exec" {
    command = <<EOF
    az network firewall policy update --ids ${module.transit-vnet.policy_id} --dns-servers ${module.shared-vnet.private_resolver_inbound_endpoint_ip}
    EOF
  }
}

## Modify DNS Server Settings on transit virtual network
##
resource "azurerm_virtual_network_dns_servers" "dns-servers" {
  depends_on = [
    null_resource.update-policy-dns
  ]
  virtual_network_id = module.transit-vnet.id
  dns_servers       = [
    module.transit-vnet.azfw_private_ip
  ]
}

## Create a workload virtual network
##
module "workload-vnet" {
  depends_on = [
    azurerm_resource_group.rgwork,
    module.shared-vnet
  ]

  source              = "../../modules/vnet/workload-generic"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name

  address_space_vnet = [var.vnet_cidr_wl]
  subnet_cidr_app    = [cidrsubnet(var.vnet_cidr_wl, 8, 0)]
  subnet_cidr_data     = [cidrsubnet(var.vnet_cidr_wl, 8, 1)]
  subnet_cidr_svc   = [cidrsubnet(var.vnet_cidr_wl, 8, 2)]
  subnet_cidr_agw = [cidrsubnet(var.vnet_cidr_wl, 8, 3)]
  subnet_cidr_apim = [cidrsubnet(var.vnet_cidr_wl, 8, 4)]
  subnet_cidr_mgmt = [cidrsubnet(var.vnet_cidr_wl, 8, 5)]
  subnet_cidr_vint = [cidrsubnet(var.vnet_cidr_wl, 8, 6)]
  
  fw_private_ip = module.transit-vnet.azfw_private_ip
  dns_servers = [
    module.transit-vnet.azfw_private_ip
  ]
  name_hub = module.transit-vnet.name
  resource_group_name_hub = azurerm_resource_group.rgtran.name
  vnet_id_hub = module.transit-vnet.id
  name_shared = module.shared-vnet.name
  resource_group_name_shared = azurerm_resource_group.rgshared.name
  sub_id_shared = data.azurerm_subscription.current.subscription_id

  law_resource_id      = module.law.id

  storage_account_id_flow_logs = module.storage_account_flow_logs.id
  network_watcher_resource_id  = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.network_watcher_resource_group_name}/providers/Microsoft.Network/networkWatchers/${var.network_watcher_name}${var.location}"
  traffic_analytics_workspace_guid     = module.law.workspace_id
  traffic_analytics_workspace_id       = module.law.id
  traffic_analytics_workspace_location = module.law.location

  tags = var.tags
}





