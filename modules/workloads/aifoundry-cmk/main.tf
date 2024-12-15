# Create resource group
#
resource "azurerm_resource_group" "rg_work" {

  name     = "rgaif${var.location_code}${var.random_string}"
  location = var.location

  tags = var.tags
}

# Create a Log Analytics Workspace
#
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "law${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_work.name

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
#
resource "azurerm_monitor_diagnostic_setting" "diag_base" {
  depends_on = [azurerm_log_analytics_workspace.log_analytics_workspace]

  name                       = "diag_base"
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
#
resource "azurerm_application_insights" "aifoundry_appins" {
  depends_on = [
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]
  name                = "${local.app_insights_prefix}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_work.name
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  application_type    = "other"
}

# Create storage account which will be default storage account for AI Foundry Hub
#
module "storage_account_ai_foundry" {

  source              = "../../storage-account"
  purpose             = var.purpose
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_access = [
    {
      endpoint_resource_id = "/subscriptions/${var.sub_id}/resourcegroups/*/providers/Microsoft.MachineLearningServices/workspaces/*"
    }
  ]
  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

# Create storage account which will be hold data to be processed by AI foundry
#
module "storage_account_data" {

  source              = "../../storage-account"
  purpose             = "${var.purpose}data"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags
  resource_access = [
    {
      endpoint_resource_id = "/subscriptions/${var.sub_id}/resourcegroups/*/providers/Microsoft.MachineLearningServices/workspaces/*"
    }
  ]
  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

# Create Key Vault which will hold secrets for AI Foundry and assign user the Key Vault Administrator role over it
#
module "keyvault_aifoundry_data" {

  source              = "../../key-vault"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  purpose             = var.purpose
  law_resource_id     = azurerm_log_analytics_workspace.log_analytics_workspace.id
  kv_admin_object_id  = var.user_object_id

  tags = var.tags
}

# Create an Azure OpenAI Service instance
#
module "openai_aifoundry" {

  source                = "../../aoai"
  random_string         = var.random_string
  location              = local.openai_region
  location_code         = local.openai_region_code
  resource_group_name   = azurerm_resource_group.rg_work.name
  purpose               = var.purpose
  law_resource_id       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  custom_subdomain_name = "${var.purpose}${var.random_string}"

  tags = var.tags
}

# Create an Azure AI Search instance
#
module "ai_search" {
  providers = {
    azapi = azapi
  }

  source              = "../../ai-search"
  purpose             = var.purpose
  random_string       = var.random_string
  resource_group_name = azurerm_resource_group.rg_work.name
  resource_group_id   = azurerm_resource_group.rg_work.id
  location            = var.location
  location_code       = var.location_code

  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  tags = var.tags
}

# Create a user assigned managed identity to be used by the AI Foundry Hub
#
resource "azurerm_user_assigned_identity" "umi_hub" {
  depends_on = [
    azurerm_resource_group.rg_work,
    azurerm_application_insights.aifoundry_appins,
    module.storage_account_ai_foundry,
    module.storage_account_data,
    module.ai_search,
    module.keyvault_aifoundry_data,
    module.openai_aifoundry
  ]

  name                = "${local.umi_prefix}${var.purpose}${var.location_code}${var.random_string}"
  resource_group_name = azurerm_resource_group.rg_work.name
  location            = var.location

  tags = var.tags
}

# Pause for 10 seconds to allow the managed identity that was created to be replicated
#
resource "time_sleep" "wait_umi_creation" {
  depends_on = [azurerm_user_assigned_identity.umi_hub]

  create_duration = "10s"
}

# Create Key Vault which will hold the key used for the key for CMNK of the Foundry instance. Add access policies (required due to no RBAC support at this time for this) to allow 
# the managed identity access to the key for CMK encryption. Also allow terraform identity full access to the key vault
#
module "keyvault_aifoundry_cmk" {
  depends_on = [
    time_sleep.wait_umi_creation
  ]

  source              = "../../key-vault"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  purpose             = "${var.purpose}cmk"
  law_resource_id     = azurerm_log_analytics_workspace.log_analytics_workspace.id

  purge_protection = true

  kv_admin_object_id  = var.user_object_id
  rbac_enabled        = false
  access_policies = [
    {
      object_id = data.azurerm_client_config.identity_config.object_id
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "Purge"
      ],
      key_permissions = [
        "Get",
        "List",
        "Delete",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "Purge",
        "Release",
        "Decrypt",
        "Encrypt",
        "UnwrapKey",
        "WrapKey",
        "Verify",
        "Sign",
        "GetRotationPolicy",
        "SetRotationPolicy",
        "Rotate"
      ],
      certificate_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "Purge"
      ]
    },
    {
      object_id = azurerm_user_assigned_identity.umi_hub.principal_id
      secret_permissions = [
      ],
      key_permissions = [
        "Get",
        "WrapKey",
        "UnwrapKey"
      ],
      certificate_permissions = [
      ]
    }
  ]
  firewall_default_action = "Deny"
  firewall_bypass = "AzureServices"
  firewall_ip_rules = [
    var.tf_ip_address
  ]

  tags = var.tags
}

# Create the CMK used to encrypt the Azure Foundry instance
#
resource "azurerm_key_vault_key" "key_cmk" {
  depends_on = [
    module.keyvault_aifoundry_cmk
  ]

  name         = "cmk"
  key_vault_id = module.keyvault_aifoundry_cmk.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

# Create a role assignments necessary for the managed identity
#

# Create role assignment on resource group that will include hub, project, and supporting resources to allow managed identity to manage resources
resource "azurerm_role_assignment" "umi_rg_contributor" {
  depends_on = [
    time_sleep.wait_umi_creation
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${azurerm_user_assigned_identity.umi_hub.name}cont")
  scope                = azurerm_resource_group.rg_work.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Create role assignment on Application Insights instance to allow managed identity to write logs and metrics to it
resource "azurerm_role_assignment" "umi_appin_contributor" {
  depends_on = [
    azurerm_role_assignment.umi_rg_contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${azurerm_application_insights.aifoundry_appins.name}${azurerm_user_assigned_identity.umi_hub.name}cont")
  scope                = azurerm_application_insights.aifoundry_appins.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Create role assignment on default storage account to allow managed identity to access the storage account when needed to read and write blobs
resource "azurerm_role_assignment" "umi_aifoundry_st_blob_data_contributor" {
  depends_on = [
    azurerm_role_assignment.umi_appin_contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${module.storage_account_ai_foundry.name}${azurerm_user_assigned_identity.umi_hub.name}blobdata")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Create role assignment on default storage account to allow managed identity to access the storage account when needed to read and write files. This is used for Jupyter notebooks and Prompt Flow files
resource "azurerm_role_assignment" "umi_aifoundry_st_file_data_contributor" {
  depends_on = [
    azurerm_role_assignment.umi_aifoundry_st_blob_data_contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${module.storage_account_ai_foundry.name}${azurerm_user_assigned_identity.umi_hub.name}filedata")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Create role assignment on storage account that will host user uploaded data to allow managed identity to access the storage account when needed to read and write blobs
resource "azurerm_role_assignment" "umi_data_st_blob_data_contributor" {
  depends_on = [
    azurerm_role_assignment.umi_aifoundry_st_file_data_contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${module.storage_account_data.name}${azurerm_user_assigned_identity.umi_hub.name}blobdata")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Create role assignment on storage account that will host user uploaded data to allow managed identity to access the storage account when needed to read and write files
resource "azurerm_role_assignment" "umi_data_st_file_data_contributor" {
  depends_on = [
    azurerm_role_assignment.umi_data_st_blob_data_contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${module.storage_account_data.name}${azurerm_user_assigned_identity.umi_hub.name}filedata")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Create role assignment on default Key Vault to allow managed identity to access the Key Vault when needed to read and write secrets required by the workspace and connections
resource "azurerm_role_assignment" "umi_data_kv_admin" {
  depends_on = [
    azurerm_role_assignment.umi_data_st_file_data_contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${module.keyvault_aifoundry_data.name}${azurerm_user_assigned_identity.umi_hub.name}kvadmin")
  scope                = module.keyvault_aifoundry_data.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.umi_hub.principal_id
}

# Pause for 120 seconds to allow the role assignments to be replicated
#
resource "time_sleep" "wait_umi_role_assignments" {
  depends_on = [
    azurerm_role_assignment.umi_data_kv_admin
  ]

  create_duration = "120s"
}

# Create the AI Foundry Hub and its diagnostic settings
#
resource "azapi_resource" "foundry_hub" {
  depends_on = [
    time_sleep.wait_umi_role_assignments
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  name                      = "${local.ai_foundry_hub_prefix}${var.purpose}${var.location_code}${var.random_string}"
  parent_id                 = azurerm_resource_group.rg_work.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.umi_hub.id}" = {}
      }
    }

    kind = "Hub"
    sku = {
      tier = "Basic"
      name = "Basic"
    }

    properties = {
      friendlyName = "Sample_Hub"
      description  = "Sample AI Foundary Hub"

      applicationInsights = azurerm_application_insights.aifoundry_appins.id
      keyVault            = module.keyvault_aifoundry_data.id
      storageAccount      = module.storage_account_ai_foundry.id

      encryption = {
        status = "Enabled" 
        keyVaultProperties = {
            keyVaultArmId = module.keyvault_aifoundry_cmk.id
            keyIdentifier = azurerm_key_vault_key.key_cmk.id
        }
      }

      publicNetworkAccess = "disabled"
      managedNetwork = {
        isolationMode = "AllowOnlyApprovedOutbound"
        firewallSku   = "Standard"
        outboundRules = {
          managed_pe_aoai = {
            type = "PrivateEndpoint"
            destination = {
              serviceResourceId = module.openai_aifoundry.id
              subresourceTarget = "account"
            }
          }
          managed_pe_aisearch = {
            type = "PrivateEndpoint"
            destination = {
              serviceResourceId = module.ai_search.id
              subresourceTarget = "SearchService"
            }
          }
          AllowPypi = {
            type        = "FQDN"
            destination = "pypi.org"
            category    = "UserDefined"
          }
          AllowAnacondaCom = {
            type        = "FQDN"
            destination = "anaconda.com"
            category    = "UserDefined"
          }
          AllowAnacondaComWildcard = {
            type        = "FQDN"
            destination = "*.anaconda.com"
            category    = "UserDefined"
          }
          AllowAnacondaOrgWildcard = {
            type        = "FQDN"
            destination = "*.anaconda.org"
            category    = "UserDefined"
          }
        }
      }

      primaryUserAssignedIdentity = azurerm_user_assigned_identity.umi_hub.id
      allowRoleAssignmentOnRg     = true
      systemDatastoresAuthMode    = "identity"

      workspaceHubConfig = {
        defaultWorkspaceResourceGroup = azurerm_resource_group.rg_work.id
      }

    }

    tags = var.tags

  }

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "foundry_hub_diag_base" {
  depends_on = [
    azapi_resource.foundry_hub,
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]

  name                       = "diag_base"
  target_resource_id         = azapi_resource.foundry_hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  enabled_log {
    category = "ComputeInstanceEvent"
  }
  metric {
    category = "AllMetrics"
  }
}

# Create a AI foundry Connection to Azure OpenAI Service
#
resource "azapi_resource" "workspace_openai_connection" {
  depends_on = [
    module.openai_aifoundry,
    azapi_resource.foundry_hub
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name                      = "conn${module.openai_aifoundry.name}"
  parent_id                 = azapi_resource.foundry_hub.id
  schema_validation_enabled = true

  body = {
    properties = {
      authType      = "AAD"
      category      = "AzureOpenAI"
      isSharedToAll = true
      target        = module.openai_aifoundry.endpoint
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-10-21"
        Location   = local.openai_region
        ResourceId = module.openai_aifoundry.id
      }
    }
  }
}

# Create a AI foundry Connection to AI Search
#
resource "azapi_resource" "workspace_aisearch_connection" {
  depends_on = [
    module.ai_search,
    azapi_resource.foundry_hub
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces/connections@2024-10-01-preview"
  name                      = "conn${module.ai_search.name}"
  parent_id                 = azapi_resource.foundry_hub.id
  schema_validation_enabled = true

  body = {
    properties = {
      authType      = "AAD"
      category      = "CognitiveSearch"
      isSharedToAll = true
      target        = "https://${module.ai_search.name}.search.windows.net"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-05-01-preview"
        ResourceId = module.ai_search.id
      }
    }
  }
}

# Create a Private Endpoints
#

# Create a Private Endpoints for Azure Storage Accounts
module "private_endpoint_st_aifoundry_blob" {
  depends_on = [
    azapi_resource.foundry_hub
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_ai_foundry.name
  resource_id      = module.storage_account_ai_foundry.id
  subresource_name = "blob"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
}

module "private_endpoint_st_data_blob" {
  depends_on = [module.private_endpoint_st_aifoundry_blob]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_data.name
  resource_id      = module.storage_account_data.id
  subresource_name = "blob"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
}

module "private_endpoint_st_aifoundry_file" {
  depends_on = [module.private_endpoint_st_data_blob]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_ai_foundry.name
  resource_id      = module.storage_account_ai_foundry.id
  subresource_name = "file"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  ]
}

module "private_endpoint_st_data_file" {
  depends_on = [module.private_endpoint_st_aifoundry_file]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_data.name
  resource_id      = module.storage_account_data.id
  subresource_name = "file"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  ]
}

module "private_endpoint_st_aifoundry_table" {
  depends_on = [module.private_endpoint_st_data_file]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_ai_foundry.name
  resource_id      = module.storage_account_ai_foundry.id
  subresource_name = "table"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
  ]
}

module "private_endpoint_st_data_table" {
  depends_on = [module.private_endpoint_st_aifoundry_table]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_data.name
  resource_id      = module.storage_account_data.id
  subresource_name = "table"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
  ]
}

module "private_endpoint_st_aifoundry_queue" {
  depends_on = [module.private_endpoint_st_data_table]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_ai_foundry.name
  resource_id      = module.storage_account_ai_foundry.id
  subresource_name = "queue"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  ]
}

module "private_endpoint_st_data_queue" {
  depends_on = [module.private_endpoint_st_aifoundry_queue]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_data.name
  resource_id      = module.storage_account_data.id
  subresource_name = "queue"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  ]
}

module "private_endpoint_st_aifoundry_dfs" {
  depends_on = [module.private_endpoint_st_data_queue]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_ai_foundry.name
  resource_id      = module.storage_account_ai_foundry.id
  subresource_name = "dfs"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"
  ]
}

module "private_endpoint_st_data_dfs" {
  depends_on = [module.private_endpoint_st_aifoundry_dfs]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.storage_account_data.name
  resource_id      = module.storage_account_data.id
  subresource_name = "dfs"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"
  ]
}

# Create a Private Endpoint for the AI Search instance
module "private_endpoint_ai_search" {
  depends_on = [
    module.private_endpoint_st_data_dfs
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.ai_search.name
  resource_id      = module.ai_search.id
  subresource_name = "searchService"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net"
  ]
}

# Create a Private Endpoint for the Azure OpenAI Service instance
module "private_endpoint_openai" {
  depends_on = [
    module.private_endpoint_ai_search
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.openai_aifoundry.name
  resource_id      = module.openai_aifoundry.id
  subresource_name = "account"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
  ]
}

# Create a Private Endpoints for the central Key Vault instance
module "private_endpoint_kv_data" {
  depends_on = [module.private_endpoint_openai]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.keyvault_aifoundry_data.name
  resource_id      = module.keyvault_aifoundry_data.id
  subresource_name = "vault"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}

# Create a Private Endpoints for CMK Key Vault instance
module "private_endpoint_kv_cmk" {
  depends_on = [
    module.private_endpoint_kv_data
]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = module.keyvault_aifoundry_cmk.name
  resource_id      = module.keyvault_aifoundry_cmk.id
  subresource_name = "vault"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}

# Create a Private Endpoints Azure Foundry Hub instance
module "private_endpoint_foundry_hub" {
  depends_on = [
    module.private_endpoint_kv_cmk
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rg_work.name
  tags                = var.tags

  resource_name    = azapi_resource.foundry_hub.name
  resource_id      = azapi_resource.foundry_hub.id
  subresource_name = "amlworkspace"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms",
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net"
  ]
}

# Create an AI Foundry Project
#
resource "azapi_resource" "foundry_project" {
  depends_on = [
    module.private_endpoint_foundry_hub
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  name                      = "${local.ai_foundry_project_prefix}${var.purpose}${var.location_code}${var.random_string}"
  parent_id                 = azurerm_resource_group.rg_work.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    identity = {
      type = "SystemAssigned"
    }

    kind = "Project"
    sku = {
      tier = "Basic"
      name = "Basic"
    }

    properties = {
      friendlyName = "Sample_Project"
      description  = "Sample AI Foundry Project"

      hubResourceId = azapi_resource.foundry_hub.id

      allowRoleAssignmentOnRg  = false
      systemDatastoresAuthMode = "identity"

      workspaceHubConfig = {
        defaultWorkspaceResourceGroup = azurerm_resource_group.rg_work.id
      }

    }

    tags = var.tags

  }

  response_export_values = [
    "identity.principalId"
  ]

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

# Create role assignments
#

# Create role assignments granting the user permissions to the storage accounts
resource "azurerm_role_assignment" "blob_perm_aifoundry_sa_user" {
  depends_on = [
    module.private_endpoint_foundry_hub
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.storage_account_ai_foundry.name}blob")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_aifoundry_sa_user" {
  depends_on = [
    azurerm_role_assignment.blob_perm_aifoundry_sa_user
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.storage_account_ai_foundry.name}file")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "blob_perm_data_sa_user" {
  depends_on = [
    azurerm_role_assignment.file_perm_aifoundry_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.storage_account_data.name}blob")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_data_sa_user" {
  depends_on = [
    azurerm_role_assignment.blob_perm_data_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.storage_account_data.name}file")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.user_object_id
}

# Create role assignment granting the user permission to the AI Foundry Hub and project
resource "azurerm_role_assignment" "ai_foundry_hub_admin" {
  depends_on = [
    azurerm_role_assignment.file_perm_data_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${azapi_resource.foundry_hub.name}aidev")
  scope                = azapi_resource.foundry_hub.id
  role_definition_name = "Azure AI Developer"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "ai_foundry_project_admin" {
  depends_on = [
    azurerm_role_assignment.file_perm_data_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${azapi_resource.foundry_project.name}aidev")
  scope                = azapi_resource.foundry_project.id
  role_definition_name = "Azure AI Developer"
  principal_id         = var.user_object_id
}

# Create the role assignment granting the user permission to the Azure OpenAI Service instance
resource "azurerm_role_assignment" "openai_user_contributor" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.openai_aifoundry.name}cont")
  scope                = module.openai_aifoundry.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = var.user_object_id
}

# Create the role assignments granting the user permission to the AI Search instance
resource "azurerm_role_assignment" "aisearch_user_service_contributor" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.ai_search.name}servicecont")
  scope                = module.ai_search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "aisearch_user_data_contributor" {
  depends_on = [
    azurerm_role_assignment.aisearch_user_service_contributor
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rg_work.name}${var.user_object_id}${module.ai_search.name}datacont")
  scope                = module.ai_search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.user_object_id
}
