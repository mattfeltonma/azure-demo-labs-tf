# Create resource group
#
resource "azurerm_resource_group" "rgwork" {

  name     = "rgaml${local.location_short}${var.random_string}"
  location = var.location

  tags = var.tags
}

# Create a Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "law${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

# Configure diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  depends_on = [azurerm_log_analytics_workspace.log_analytics_workspace]

  name                       = "diag-base"
  target_resource_id         = azurerm_log_analytics_workspace.log_analytics_workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "SummaryLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Create Application Insights
resource "azurerm_application_insights" "aml-appins" {
  depends_on = [ 
    azurerm_log_analytics_workspace.log_analytics_workspace 
  ]
  name                = "${local.app_insights_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  application_type    = "other"
}

# Create storage account which will be default storage account for AML Workspace
#
module "storage_account_aml_default" {

  source              = "../storage-account"
  purpose             = "${var.purpose}"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  resource_access = [
    {
      endpoint_resource_id = "/subscriptions/${var.sub_id}/resourcegroups/*/providers/Microsoft.MachineLearningServices/workspaces/*"
    }
  ]
  tags                = var.tags

  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

# Create storage account which will be hold data to be processed by AML Workspace
#
module "storage_account_data" {

  source              = "../storage-account"
  purpose             = "${var.purpose}data"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  resource_access = [
    {
      endpoint_resource_id = "/subscriptions/${var.sub_id}/resourcegroups/*/providers/Microsoft.MachineLearningServices/workspaces/*"
    }
  ]
  tags                = var.tags

  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

# Create Key Vault which will hold secrets for the AML workspace and assign user the Key Vault Administrator role over it
#
module "keyvault_aml" {

  source              = "../key-vault"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  purpose             = var.purpose
  law_resource_id     = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags = var.tags

  kv_admin_object_id  = var.user_object_id

  firewall_default_action = "Deny"
  firewall_bypass = "AzureServices"
}

## Create a Private Endpoints for storage account and Key Vault
##
module "private_endpoint_st_aml_blob" {
  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_aml_default.name
  resource_id       = module.storage_account_aml_default.id
  subresource_name = "blob"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
}

module "private_endpoint_st_data_blob" {
  depends_on = [ module.private_endpoint_st_aml_blob ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_data.name
  resource_id       = module.storage_account_data.id
  subresource_name = "blob"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
}

module "private_endpoint_st_aml_file" {
  depends_on = [ module.private_endpoint_st_data_blob ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_aml_default.name
  resource_id       = module.storage_account_aml_default.id
  subresource_name = "file"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  ]
}

module "private_endpoint_st_data_file" {
  depends_on = [ module.private_endpoint_st_aml_file ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_data.name
  resource_id       = module.storage_account_data.id
  subresource_name = "file"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  ]
}

module "private_endpoint_st_aml_table" {
  depends_on = [ module.private_endpoint_st_data_file]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_aml_default.name
  resource_id       = module.storage_account_aml_default.id
  subresource_name = "table"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
  ]
}

module "private_endpoint_st_data_table" {
  depends_on = [ module.private_endpoint_st_aml_table ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_data.name
  resource_id       = module.storage_account_data.id
  subresource_name = "table"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
  ]
}

module "private_endpoint_st_aml_queue" {
  depends_on = [ module.private_endpoint_st_data_table ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_aml_default.name
  resource_id       = module.storage_account_aml_default.id
  subresource_name = "queue"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  ]
}

module "private_endpoint_st_data_queue" {
  depends_on = [ module.private_endpoint_st_aml_queue ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_data.name
  resource_id       = module.storage_account_data.id
  subresource_name = "queue"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  ]
}

module "private_endpoint_st_aml_dfs" {
  depends_on = [ module.private_endpoint_st_data_queue ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_aml_default.name
  resource_id       = module.storage_account_aml_default.id
  subresource_name = "dfs"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"
  ]
}

module "private_endpoint_st_data_dfs" {
  depends_on = [ module.private_endpoint_st_aml_dfs ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_data.name
  resource_id       = module.storage_account_data.id
  subresource_name = "dfs"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"
  ]
}

module "private_endpoint_kv" {
  depends_on = [ module.private_endpoint_st_data_dfs ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.keyvault_aml.name
  resource_id       = module.keyvault_aml.id
  subresource_name = "vault"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}

# Create required role assignments for the user who will administer the AML Workspace
# Note that user has already been granted the Key Vault Administrator role over the Key Vault
#
resource "azurerm_role_assignment" "blob_perm_aml_sa" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_aml_default.name}blob")
  scope                = module.storage_account_aml_default.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_aml_sa" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_aml_default.name}file")
  scope                = module.storage_account_aml_default.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "blob_perm_data_sa" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_data.name}blob")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_data_sa" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_data.name}file")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.user_object_id
}

