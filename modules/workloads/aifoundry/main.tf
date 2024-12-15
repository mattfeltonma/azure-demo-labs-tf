# Create resource group
#
resource "azurerm_resource_group" "rgwork" {

  name     = "rgaif${var.location_code}${var.random_string}"
  location = var.location

  tags = var.tags
}

# Create a Log Analytics Workspace
#
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "law${var.purpose}${var.location_code}${var.random_string}"
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
#
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
#
resource "azurerm_application_insights" "aifoundry-appins" {
  depends_on = [
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]
  name                = "${local.app_insights_prefix}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
module "keyvault_aifoundry" {

  source              = "../../key-vault"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name   = azurerm_resource_group.rgwork.name
  purpose               = var.purpose
  law_resource_id       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  custom_subdomain_name = var.random_string

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
  resource_group_name = azurerm_resource_group.rgwork.name
  resource_group_id   = azurerm_resource_group.rgwork.id
  location            = var.location
  location_code       = var.location_code

  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  tags = var.tags
}

# Create a user assigned managed identity to be used by the AI Foundry Hub
#
resource "azurerm_user_assigned_identity" "umi-hub" {
  depends_on = [
    azurerm_resource_group.rgwork,
    azurerm_application_insights.aifoundry-appins,
    module.storage_account_ai_foundry,
    module.storage_account_data,
    module.ai_search,
    module.keyvault_aifoundry,
    module.openai_aifoundry
  ]

  name                = "${local.umi_prefix}${var.purpose}${var.location_code}${var.random_string}"
  resource_group_name = azurerm_resource_group.rgwork.name
  location            = var.location

  tags = var.tags
}

# Pause for 10 seconds to allow the managed identity that was created to be replicated
#
resource "time_sleep" "wait-umi-creation" {
  depends_on = [azurerm_user_assigned_identity.umi-hub]

  create_duration = "10s"
}

# Create a role assignments necessary for the managed identity
#
resource "azurerm_role_assignment" "umi-rg-contributor" {
  depends_on = [
    time_sleep.wait-umi-creation
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${azurerm_user_assigned_identity.umi-hub.name}cont")
  scope                = azurerm_resource_group.rgwork.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

resource "azurerm_role_assignment" "umi-appin-contributor" {
  depends_on = [
    azurerm_role_assignment.umi-rg-contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${azurerm_application_insights.aifoundry-appins.name}${azurerm_user_assigned_identity.umi-hub.name}cont")
  scope                = azurerm_application_insights.aifoundry-appins.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

resource "azurerm_role_assignment" "umi-aifoundry-st-blob-data-contributor" {
  depends_on = [
    azurerm_role_assignment.umi-appin-contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${module.storage_account_ai_foundry.name}${azurerm_user_assigned_identity.umi-hub.name}blobdata")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

resource "azurerm_role_assignment" "umi-aifoundry-st-file-data-contributor" {
  depends_on = [
    azurerm_role_assignment.umi-aifoundry-st-blob-data-contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${module.storage_account_ai_foundry.name}${azurerm_user_assigned_identity.umi-hub.name}filedata")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

resource "azurerm_role_assignment" "umi-data-st-blob-data-contributor" {
  depends_on = [
    azurerm_role_assignment.umi-aifoundry-st-file-data-contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${module.storage_account_data.name}${azurerm_user_assigned_identity.umi-hub.name}blobdata")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

resource "azurerm_role_assignment" "umi-data-st-file-data-contributor" {
  depends_on = [
    azurerm_role_assignment.umi-data-st-blob-data-contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${module.storage_account_data.name}${azurerm_user_assigned_identity.umi-hub.name}filedata")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

resource "azurerm_role_assignment" "umi-data-kv-admin" {
  depends_on = [
    azurerm_role_assignment.umi-data-st-file-data-contributor
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${module.keyvault_aifoundry.name}${azurerm_user_assigned_identity.umi-hub.name}kvadmin")
  scope                = module.keyvault_aifoundry.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.umi-hub.principal_id
}

# Pause for 120 seconds to allow the role assignments to be replicated
#
resource "time_sleep" "wait-umi-role-assignments" {
  depends_on = [
    azurerm_role_assignment.umi-data-kv-admin
  ]

  create_duration = "120s"
}

# Create the AI Foundry Hub
#
resource "azapi_resource" "foundry-hub" {
  depends_on = [
    time_sleep.wait-umi-role-assignments
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  name                      = "${local.ai_foundry_hub_prefix}${var.purpose}${var.location_code}${var.random_string}"
  parent_id                 = azurerm_resource_group.rgwork.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        "${azurerm_user_assigned_identity.umi-hub.id}" = {}
      }
    }

    kind = "Hub"
    sku = {
      tier = "Basic"
      name = "Basic"
    }

    properties = {
      friendlyName = "Sample-Hub"
      description  = "Sample AI Foundary Hub"

      applicationInsights = azurerm_application_insights.aifoundry-appins.id
      keyVault            = module.keyvault_aifoundry.id
      storageAccount      = module.storage_account_ai_foundry.id

      publicNetworkAccess = "disabled"
      managedNetwork = {
        isolationMode = "AllowOnlyApprovedOutbound"
        firewallSku   = "Standard"
        outboundRules = {
          managed-pe-aoai = {
            type = "PrivateEndpoint"
            destination = {
              serviceResourceId = module.openai_aifoundry.id
              subresourceTarget = "account"
            }
          }
          managed-pe-aisearch = {
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

      primaryUserAssignedIdentity = azurerm_user_assigned_identity.umi-hub.id
      allowRoleAssignmentOnRg     = true
      systemDatastoresAuthMode    = "identity"

      workspaceHubConfig = {
        defaultWorkspaceResourceGroup = azurerm_resource_group.rgwork.id
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

resource "azurerm_monitor_diagnostic_setting" "foundry-hub-diag-base" {
  depends_on = [
    azapi_resource.foundry-hub,
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]

  name                       = "diag-base"
  target_resource_id         = azapi_resource.foundry-hub.id
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
resource "azapi_resource" "workspace-openai-connection" {
  depends_on = [
    module.openai_aifoundry,
    azapi_resource.foundry-hub
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name                      = "conn${module.openai_aifoundry.name}"
  parent_id                 = azapi_resource.foundry-hub.id
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
resource "azapi_resource" "workspace-aisearch-connection" {
  depends_on = [
    module.ai_search,
    azapi_resource.foundry-hub
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name                      = "conn${module.ai_search.name}"
  parent_id                 = azapi_resource.foundry-hub.id
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
    azapi_resource.foundry-hub
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
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
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.openai_aifoundry.name
  resource_id      = module.openai_aifoundry.id
  subresource_name = "account"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
  ]
}

# Create a Private Endpoints for Key Vault instance
module "private_endpoint_kv" {
  depends_on = [module.private_endpoint_openai]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.keyvault_aifoundry.name
  resource_id      = module.keyvault_aifoundry.id
  subresource_name = "vault"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}

# Create a Private Endpoints Azure Foundry Hub instance
module "private_endpoint_foundry_hub" {
  depends_on = [
    module.private_endpoint_kv
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = azapi_resource.foundry-hub.name
  resource_id      = azapi_resource.foundry-hub.id
  subresource_name = "amlworkspace"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms",
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net"
  ]
}

# Create an AI Foundry Project
#
resource "azapi_resource" "foundry-project" {
  depends_on = [
    module.private_endpoint_foundry_hub
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  name                      = "${local.ai_foundry_project_prefix}${var.purpose}${var.location_code}${var.random_string}"
  parent_id                 = azurerm_resource_group.rgwork.id
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
      friendlyName = "Sample-Project"
      description  = "Sample AI Foundry Project"

      hubResourceId = azapi_resource.foundry-hub.id

      allowRoleAssignmentOnRg  = false
      systemDatastoresAuthMode = "identity"

      workspaceHubConfig = {
        defaultWorkspaceResourceGroup = azurerm_resource_group.rgwork.id
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
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_ai_foundry.name}blob")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_aifoundry_sa_user" {
  depends_on = [
    azurerm_role_assignment.blob_perm_aifoundry_sa_user
  ]

  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_ai_foundry.name}file")
  scope                = module.storage_account_ai_foundry.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "blob_perm_data_sa_user" {
  depends_on = [
    azurerm_role_assignment.file_perm_aifoundry_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_data.name}blob")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "file_perm_data_sa_user" {
  depends_on = [
    azurerm_role_assignment.blob_perm_data_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.storage_account_data.name}file")
  scope                = module.storage_account_data.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.user_object_id
}

# Create role assignment granting the user permission to the AI Foundry Hub instance
resource "azurerm_role_assignment" "ai_foundry_hub_admin" {
  depends_on = [
    azurerm_role_assignment.file_perm_data_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${azapi_resource.foundry-hub.name}aidev")
  scope                = azapi_resource.foundry-hub.id
  role_definition_name = "Azure AI Developer"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "ai_foundry_project_admin" {
  depends_on = [
    azurerm_role_assignment.file_perm_data_sa_user
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${azapi_resource.foundry-project.name}aidev")
  scope                = azapi_resource.foundry-project.id
  role_definition_name = "Azure AI Developer"
  principal_id         = var.user_object_id
}

# Create the role assignment granting the user permission to the Azure OpenAI Service instance
resource "azurerm_role_assignment" "openai_user_contributor" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.openai_aifoundry.name}cont")
  scope                = module.openai_aifoundry.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = var.user_object_id
}

# Create the role assignments granting the user permission to the AI Search instance
resource "azurerm_role_assignment" "aisearch_user_service_contributor" {
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.ai_search.name}servicecont")
  scope                = module.ai_search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = var.user_object_id
}

resource "azurerm_role_assignment" "aisearch_user_data_contributor" {
  depends_on = [
    azurerm_role_assignment.aisearch_user_service_contributor
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${module.ai_search.name}datacont")
  scope                = module.ai_search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.user_object_id
}
