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

# Create resource group
#
resource "azurerm_resource_group" "rgwork" {

  name     = "rgwork${local.location_short}${random_string.unique.result}"
  location = var.location

  tags = local.tags
}

# Grant the Terraform identity access to Key Vault secrets, certificates, and keys all Key Vaults
#
resource "azurerm_role_assignment" "assign-tf" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${data.azurerm_client_config.identity_config.object_id}")
  scope                = azurerm_resource_group.rgwork.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.identity_config.object_id
}

# Create Log Analytics Workspace
#
module "law" {
  depends_on = [
    azurerm_resource_group.rgwork
  ]

  source              = "../../modules/monitor/log-analytics-workspace"
  random_string       = random_string.unique.result
  purpose             = "cnt"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = local.tags
}

# Create Storage Account for Flow Logs
#
module "storage_account_flow_logs" {
  depends_on = [
    azurerm_resource_group.rgwork,
    module.law
  ]

  source              = "../../modules/storage-account"
  purpose             = "flv"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = local.tags

  law_resource_id = module.law.id
}

## Create centralized Azure Key Vault
##
module "central-keyvault" {
  depends_on = [
    azurerm_resource_group.rgwork
  ]

  source              = "../../modules/key-vault"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
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

## Create a workload virtual network
##
module "workload-vnet" {
  depends_on = [
    azurerm_resource_group.rgwork
  ]

  source              = "../../modules/vnet/standalone/workload"
  random_string       = random_string.unique.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  sub_id = data.azurerm_subscription.current.subscription_id

  admin_password = var.admin_password
  admin_username = var.admin_username
  sku_tools_os = var.sku_tools_os
  sku_tools_size = var.sku_tools_size

  private_dns_namespaces = local.private_dns_namespaces_with_regional_zones

  address_space_vnet = [var.vnet_cidr_wl]
  subnet_cidr_app    = [cidrsubnet(var.vnet_cidr_wl, 8, 0)]
  subnet_cidr_data     = [cidrsubnet(var.vnet_cidr_wl, 8, 1)]
  subnet_cidr_svc   = [cidrsubnet(var.vnet_cidr_wl, 8, 2)]
  subnet_cidr_agw = [cidrsubnet(var.vnet_cidr_wl, 8, 3)]
  subnet_cidr_apim = [cidrsubnet(var.vnet_cidr_wl, 8, 4)]
  subnet_cidr_mgmt = [cidrsubnet(var.vnet_cidr_wl, 8, 5)]
  subnet_cidr_vint = [cidrsubnet(var.vnet_cidr_wl, 8, 6)]
  subnet_cidr_tools = [cidrsubnet(var.vnet_cidr_wl, 8, 7)]
  trusted_ip_address = var.trusted_ip_address

  law_resource_id      = module.law.id
  dce_id = module.law.dce_id
  dcr_id_windows = module.law.dcr_id_windows
  
  storage_account_id_flow_logs = module.storage_account_flow_logs.id
  network_watcher_resource_id  = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.network_watcher_resource_group_name}/providers/Microsoft.Network/networkWatchers/${var.network_watcher_name}${var.location}"
  traffic_analytics_workspace_guid     = module.law.workspace_id
  traffic_analytics_workspace_id       = module.law.id
  traffic_analytics_workspace_location = module.law.location

  tags = var.tags
}





