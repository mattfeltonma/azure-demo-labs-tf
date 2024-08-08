# Create resource group
#
resource "azurerm_resource_group" "rgwork" {

  name     = "rgaistudio-res${local.location_short}${var.random_string}"
  location = var.location

  tags = var.tags
}

# Create Log Analytics Workspace
#
module "law" {
  depends_on = [
    azurerm_resource_group.rgwork
  ]

  source              = "../monitor/log-analytics-workspace"
  random_string       = var.random_string
  purpose             = "${var.purpose}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags
}

# Create storage account which will be default storage account for AI Studio Hub
#
module "storage_account_ai_studio" {

  source              = "../storage-account"
  purpose             = "${var.purpose}"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  law_resource_id = module.law.id
}

# Create storage account which will be hold data to be processed by AI Studio
#
module "storage_account_data" {

  source              = "../storage-account"
  purpose             = "${var.purpose}data"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  law_resource_id = module.law.id
}

# Create Key Vault which will hold secrets for AI Studio and assign user the Key Vault Administrator role over it
#
module "keyvault_aistudio" {

  source              = "../key-vault"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  purpose             = var.purpose
  law_resource_id     = module.law.id
  kv_admin_object_id  = var.user_object_id

  tags = var.tags
}

# Create an Azure OpenAI Service instance
#
module "openai_aistudio" {

  source              = "../aoai"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  purpose             = var.purpose
  law_resource_id     = module.law.id

  tags = var.tags
}

## Create a Private Endpoints for storage account and Key Vault
##
module "private_endpoint_st_aistudio_blob" {
  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_ai_studio.name
  resource_id       = module.storage_account_ai_studio.id
  subresource_name = "blob"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
}

module "private_endpoint_st_data_blob" {
  depends_on = [ module.private_endpoint_st_aistudio_blob ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.location
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

module "private_endpoint_st_aistudio_file" {
  depends_on = [ module.private_endpoint_st_data_blob ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.storage_account_ai_studio.name
  resource_id       = module.storage_account_ai_studio.id
  subresource_name = "file"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  ]
}

module "private_endpoint_st_data_file" {
  depends_on = [ module.private_endpoint_st_aistudio_file ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.location
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

module "private_endpoint_kv" {
  depends_on = [ module.private_endpoint_st_data_file ]

  source              = "../private-endpoint"
  random_string       = var.random_string
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name     = module.keyvault_aistudio.name
  resource_id       = module.keyvault_aistudio.id
  subresource_name = "vault"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}

# Create required role assignments for the user who will administer the AI Studio Hub
# Note that user has already been granted the Key Vault Administrator role over the Key Vault
#
resource "azurerm_role_assignment" "blob_perm_aistudio_sa" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_ai_studio.name}blob")
  scope                = module.storage_account_ai_studio.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_aistudio_sa" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_ai_studio.name}file")
  scope                = module.storage_account_ai_studio.id
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

