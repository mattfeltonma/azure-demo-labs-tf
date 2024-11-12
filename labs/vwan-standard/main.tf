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
resource "azurerm_resource_group" "rgtran-pri" {
  name     = "rgtr${local.location_code_primary}${random_string.unique.result}"
  location = var.location_primary
  tags     = local.tags
}

resource "azurerm_resource_group" "rgshared-pri" {
  name     = "rgsh${local.location_code_primary}${random_string.unique.result}"
  location = var.location_primary
  tags     = local.tags
}

resource "azurerm_resource_group" "rgwork-pri" {
  name     = "rgwl${local.location_code_primary}${random_string.unique.result}"
  location = var.location_primary

  tags = local.tags
}

resource "azurerm_resource_group" "rgtran-sec" {
  count = var.multi_region == true ? 1 : 0

  name     = "rgtr${local.location_code_secondary}${random_string.unique.result}"
  location = var.location_secondary
  tags     = local.tags
}

resource "azurerm_resource_group" "rgshared-sec" {
  count = var.multi_region == true ? 1 : 0

  name     = "rgsh${local.location_code_secondary}${random_string.unique.result}"
  location = var.location_secondary
  tags     = local.tags
}

resource "azurerm_resource_group" "rgwork-sec" {
  count = var.multi_region == true ? 1 : 0

  name     = "rgwl${local.location_code_secondary}${random_string.unique.result}"
  location = var.location_secondary
  tags     = local.tags
}

# Grant the Terraform identity access to Key Vault secrets, certificates, and keys all Key Vaults
#
resource "azurerm_role_assignment" "assign-tf-pri" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgshared-pri.id}${data.azurerm_client_config.identity_config.object_id}")
  scope                = azurerm_resource_group.rgshared-pri.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.identity_config.object_id
}

resource "azurerm_role_assignment" "assign-tf-sec" {
  count = var.multi_region == true ? 1 : 0

  name                 = uuidv5("dns", "${azurerm_resource_group.rgshared-sec[0].id}${data.azurerm_client_config.identity_config.object_id}")
  scope                = azurerm_resource_group.rgshared-sec[0].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.identity_config.object_id
}

# Create Log Analytics Workspace and Data Collection Endpoints and Data Collection Rules for Windows and Linux in primary region
#
module "law" {
  depends_on = [
    azurerm_resource_group.rgshared-pri
  ]

  source                        = "../../modules/monitor/log-analytics-workspace"
  random_string                 = random_string.unique.result
  purpose                       = local.law_purpose
  location_primary              = var.location_primary
  location_secondary            = var.location_secondary
  location_code_primary         = local.location_code_primary
  location_code_secondary       = local.location_code_secondary
  resource_group_name_primary   = azurerm_resource_group.rgshared-pri.name
  resource_group_name_secondary = var.multi_region ? try(azurerm_resource_group.rgshared-sec[0].name, null) : null
  tags                          = local.tags
}

# Create Storage Account for Flow Logs
#
module "storage-account-flow-logs-pri" {
  depends_on = [
    azurerm_resource_group.rgshared-pri,
    module.law
  ]

  source              = "../../modules/storage-account"
  purpose             = "flv"
  random_string       = random_string.unique.result
  location            = var.location_primary
  location_code       = local.location_code_primary
  resource_group_name = azurerm_resource_group.rgshared-pri.name
  tags                = local.tags

  law_resource_id = module.law.id
}

module "storage-account-flow-logs-sec" {
  count = var.multi_region == true ? 1 : 0

  depends_on = [
    azurerm_resource_group.rgshared-sec,
    module.law
  ]

  source              = "../../modules/storage-account"
  purpose             = "flv"
  random_string       = random_string.unique.result
  location            = var.location_secondary
  location_code       = local.location_code_secondary
  resource_group_name = azurerm_resource_group.rgshared-sec[0].name
  tags                = local.tags

  law_resource_id = module.law.id
}

# Create a VWAN
#
module "vwan" {
  depends_on = [
    azurerm_resource_group.rgtran-pri,
    module.law,
    module.storage-account-flow-logs-pri
  ]

  source              = "../../modules/vwan"
  random_string       = random_string.unique.result
  location            = var.location_primary
  location_code       = local.location_code_primary
  resource_group_name = azurerm_resource_group.rgtran-pri.name

  allow-branch = true
  tags         = local.tags
}

# Create VWAN Hubs
#
module "vwan-hub-pri" {
  depends_on = [
    module.vwan
  ]

  source              = "../../modules/vwan-hub"
  random_string       = random_string.unique.result
  location            = var.location_primary
  location_code       = local.location_code_primary
  resource_group_name = azurerm_resource_group.rgtran-pri.name

  vwan_id       = module.vwan.id
  address_space = local.vnet_cidr_vwanh_pri
  vpn_gateway   = true

  law_resource_id = module.law.id

  tags = local.tags
}

module "vwan-hub-sec" {
  count = var.multi_region == true ? 1 : 0

  depends_on = [
    module.vwan
  ]

  source              = "../../modules/vwan-hub"
  random_string       = random_string.unique.result
  location            = var.location_secondary
  location_code       = local.location_code_secondary
  resource_group_name = azurerm_resource_group.rgtran-sec[0].name

  vwan_id       = module.vwan.id
  address_space = local.vnet_cidr_vwanh_sec
  vpn_gateway   = true

  law_resource_id = module.law.id

  tags = local.tags
}

## Create centralized Azure Key Vault
##
module "central-keyvault" {
  depends_on = [
    azurerm_resource_group.rgshared-pri
  ]

  source                  = "../../modules/key-vault"
  random_string           = random_string.unique.result
  location                = var.location_primary
  location_code           = local.location_code_primary
  resource_group_name     = azurerm_resource_group.rgshared-pri.name
  purpose                 = "cnt"
  law_resource_id         = module.law.id
  kv_admin_object_id      = var.key_vault_admin
  firewall_default_action = "Allow"

  tags = local.tags
}

## Add virtual machine user and password to Azure Key Vault
##
resource "azurerm_key_vault_secret" "vm-credentials" {
  depends_on = [
    module.central-keyvault
  ]
  name = "vm-credentials"
  value = jsonencode({
    admin_username = var.admin_username
    admin_password = var.admin_password
  })
  key_vault_id = module.central-keyvault.id
}

## Create a workload virtual network
##
module "workload-vnet-pri" {
  count = 2

  depends_on = [
    module.vwan-hub-pri,
    azurerm_resource_group.rgwork-pri
  ]

  source              = "../../modules/vnet/vwan/workload-simple"
  random_string       = random_string.unique.result
  location            = var.location_primary
  location_code       = local.location_code_primary
  resource_group_name = azurerm_resource_group.rgwork-pri.name
  count_index         = count.index

  address_space_vnet = lookup(local.primary_region_vnet_cidrs, "wl${count.index + 1}")
  subnet_cidr_app    = cidrsubnet(lookup(local.primary_region_vnet_cidrs, "wl${count.index + 1}"), 3, 0)
  subnet_cidr_svc    = cidrsubnet(lookup(local.primary_region_vnet_cidrs, "wl${count.index + 1}"), 3, 1)

  vwan_hub_id                  = module.vwan-hub-pri.id
  vwan_associated_route_table  = module.vwan-hub-pri.default_route_table_id
  vwan_propagate_default_route = true
  vwan_propagate_route_labels = [
    "default"
  ]
  vwan_propagate_route_tables = [
    module.vwan-hub-pri.default_route_table_id
  ]

  law_resource_id = module.law.id
  dce_id          = module.law.dce_id_primary
  dcr_id_linux    = module.law.dcr_id_linux

  admin_username = var.admin_username
  admin_password = var.admin_password
  trusted_ip = var.trusted_ip
  vm_size_web    = var.sku_vm_size

  storage_account_id_flow_logs         = module.storage-account-flow-logs-pri.id
  network_watcher_resource_id          = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.network_watcher_resource_group_name}/providers/Microsoft.Network/networkWatchers/${var.network_watcher_name}${var.location_primary}"
  traffic_analytics_workspace_guid     = module.law.workspace_id
  traffic_analytics_workspace_id       = module.law.id
  traffic_analytics_workspace_location = module.law.location

  tags = local.tags
}

module "workload-vnet-sec" {
  count = var.multi_region == true ? 2 : 0

  depends_on = [
    module.vwan-hub-sec,
    module.workload-vnet-pri
  ]

  source              = "../../modules/vnet/vwan/workload-simple"
  random_string       = random_string.unique.result
  location            = var.location_secondary
  location_code       = local.location_code_secondary
  resource_group_name = azurerm_resource_group.rgwork-sec[0].name
  count_index         = count.index

  address_space_vnet = lookup(local.secondary_region_vnet_cidrs, "wl${count.index + 1}")
  subnet_cidr_app    = cidrsubnet(lookup(local.secondary_region_vnet_cidrs, "wl${count.index + 1}"), 3, 0)
  subnet_cidr_svc    = cidrsubnet(lookup(local.secondary_region_vnet_cidrs, "wl${count.index + 1}"), 3, 1)

  vwan_hub_id                  = module.vwan-hub-sec[0].id
  vwan_associated_route_table  = module.vwan-hub-sec[0].default_route_table_id
  vwan_propagate_default_route = true
  vwan_propagate_route_labels = [
    "default"
  ]
  vwan_propagate_route_tables = [
    module.vwan-hub-sec[0].default_route_table_id
  ]

  law_resource_id = module.law.id
  dce_id          = module.law.dce_id_secondary
  dcr_id_linux    = module.law.dcr_id_linux

  admin_username = var.admin_username
  admin_password = var.admin_password
  trusted_ip = var.trusted_ip
  vm_size_web    = var.sku_vm_size

  storage_account_id_flow_logs         = module.storage-account-flow-logs-sec[0].id
  network_watcher_resource_id          = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.network_watcher_resource_group_name}/providers/Microsoft.Network/networkWatchers/${var.network_watcher_name}${var.location_secondary}"
  traffic_analytics_workspace_guid     = module.law.workspace_id
  traffic_analytics_workspace_id       = module.law.id
  traffic_analytics_workspace_location = module.law.location

  tags = local.tags
}