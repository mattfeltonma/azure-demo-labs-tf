## Create resource group
##
resource "azurerm_resource_group" "rgwork" {

  name     = "rgaml${var.location_code}${var.random_string}"
  location = var.location

  tags = var.tags
}

## Create a Log Analytics Workspace
##
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

## Configure diagnostic settings
##
resource "azurerm_monitor_diagnostic_setting" "law-diag-base" {
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

## Create Application Insights
##
resource "azurerm_application_insights" "aml-appins" {
  depends_on = [
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]
  name                = "${local.app_insights_prefix}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgwork.name
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  application_type    = "other"
}

## Create storage account which will be default storage account for AML Workspace
##
module "storage_account_aml_default" {

  source                   = "../../storage-account"
  purpose                  = var.purpose
  random_string            = var.random_string
  location                 = var.location
  location_code            = var.location_code
  key_based_authentication = false

  resource_group_name = azurerm_resource_group.rgwork.name
  resource_access = [
    {
      endpoint_resource_id = "/subscriptions/${var.sub_id}/resourcegroups/*/providers/Microsoft.MachineLearningServices/workspaces/*"
    }
  ]
  tags = var.tags

  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

## Create storage account which will be hold data to be processed by AML Workspace
##
module "storage_account_data" {

  source                   = "../../storage-account"
  purpose                  = "${var.purpose}data"
  random_string            = var.random_string
  location                 = var.location
  location_code            = var.location_code
  resource_group_name      = azurerm_resource_group.rgwork.name
  key_based_authentication = false

  resource_access = [
    {
      endpoint_resource_id = "/subscriptions/${var.sub_id}/resourcegroups/*/providers/Microsoft.MachineLearningServices/workspaces/*"
    }
  ]
  tags = var.tags

  law_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

## Create Key Vault which will hold secrets for the AML workspace and assign user the Key Vault Administrator role over it
##
module "keyvault_aml" {

  source              = "../../key-vault"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  purpose             = var.purpose
  law_resource_id     = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = var.tags

  kv_admin_object_id = var.user_object_id

  firewall_default_action = "Deny"
  firewall_bypass         = "AzureServices"
}

## Create required role assignments for the user who will administer the AML Workspace
## Note that user has already been granted the Key Vault Administrator role over the Key Vault
##
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

## Create an Azure OpenAI instance
##
module "openai" {
  depends_on = [
    azurerm_machine_learning_workspace_network_outbound_rule_fqdn.tensorflow-org-wildcard,
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]

  source              = "../../aoai"
  purpose             = var.purpose
  random_string       = var.random_string
  resource_group_name = azurerm_resource_group.rgwork.name
  location            = local.openai_region
  location_code       = local.openai_region_code

  custom_subdomain_name = "${var.purpose}${var.location_code}${var.random_string}"
  law_resource_id       = azurerm_log_analytics_workspace.log_analytics_workspace.id

  tags = var.tags
}

## Create the Azure Machine Learning Workspace
##
resource "azapi_resource" "workspace" {
  depends_on = [
    azurerm_application_insights.aml-appins,
    azurerm_resource_group.rgwork,
    module.storage_account_aml_default,
    module.storage_account_data,
    module.keyvault_aml,
    module.openai
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  name                      = "${local.aml_workspace_prefix}${var.purpose}${var.location_code}${var.random_string}"
  parent_id                 = azurerm_resource_group.rgwork.id
  location                  = var.location
  schema_validation_enabled = true

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      description = "Azure Machine Learning Workspace for testing"

      applicationInsights = azurerm_application_insights.aml-appins.id
      keyVault            = module.keyvault_aml.id
      storageAccount      = module.storage_account_aml_default.id

      publicNetworkAccess = "disabled"
      managedNetwork = {
        isolationMode = "AllowOnlyApprovedOutbound"
        firewallSku   = "Standard"
        outboundRules = {
          managed-pe-aoai = {
            type = "PrivateEndpoint"
            destination = {
              serviceResourceId = module.openai.id
              subresourceTarget = "account"
            }
          }
          managed-pe-st-data-blob = {
            type = "PrivateEndpoint"
            destination = {
              serviceResourceId = module.storage_account_data.id
              subresourceTarget = "blob"
            }
          }
          managed-pe-st-data-file = {
            type = "PrivateEndpoint"
            destination = {
              serviceResourceId = module.storage_account_data.id
              subresourceTarget = "file"
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

      systemDatastoresAuthMode = "identity"

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

resource "azurerm_monitor_diagnostic_setting" "aml-diag-base" {
  depends_on = [
    azapi_resource.workspace,
    azurerm_log_analytics_workspace.log_analytics_workspace
  ]

  name                       = "diag-base"
  target_resource_id         = azapi_resource.workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  enabled_log {
    category = "AmlComputeClusterEvent"
  }
  enabled_log {
    category = "AmlComputeClusterNodeEvent"
  }
  enabled_log {
    category = "AmlComputeJobEvent"
  }
  enabled_log {
    category = "AmlComputeCpuGpuUtilization"
  }
  enabled_log {
    category = "AmlRunStatusChangedEvent"
  }
  enabled_log {
    category = "ModelsChangeEvent"
  }
  enabled_log {
    category = "ModelsReadEvent"
  }
  enabled_log {
    category = "ModelsActionEvent"
  }
  enabled_log {
    category = "DeploymentReadEvent"
  }
  enabled_log {
    category = "DeploymentEventACI"
  }
  enabled_log {
    category = "DeploymentEventAKS"
  }
  enabled_log {
    category = "InferencingOperationAKS"
  }
  enabled_log {
    category = "InferencingOperationACI"
  }
  enabled_log {
    category = "EnvironmentChangeEvent"
  }
  enabled_log {
    category = "EnvironmentReadEvent"
  }
  enabled_log {
    category = "DataLabelChangeEvent"
  }
  enabled_log {
    category = "DataLabelReadEvent"
  }
  enabled_log {
    category = "ComputeInstanceEvent"
  }
  enabled_log {
    category = "DataStoreChangeEvent"
  }
  enabled_log {
    category = "DataStoreReadEvent"
  }
  enabled_log {
    category = "DataSetChangeEvent"
  }
  enabled_log {
    category = "DataSetReadEvent"
  }
  enabled_log {
    category = "PipelineChangeEvent"
  }
  enabled_log {
    category = "PipelineReadEvent"
  }
  enabled_log {
    category = "RunEvent"
  }
  enabled_log {
    category = "RunReadEvent"
  }
  metric {
    category = "AllMetrics"
  }
}

## Create Azure RBAC Role assignment for workspace contributor
resource "azurerm_role_assignment" "wk_perm_contributor" {
  depends_on = [
    azapi_resource.workspace
  ]
  name                 = uuidv5("dns", "${azurerm_resource_group.rgwork.name}${var.user_object_id}${azapi_resource.workspace.name}ws")
  scope                = azapi_resource.workspace.id
  role_definition_name = "Contributor"
  principal_id         = var.user_object_id
}

## Create a AML Workspace Connection to the Azure OpenAI Instance
##
resource "azapi_resource" "workspace-openai-connection" {
  depends_on = [
    module.openai,
    azapi_resource.workspace
  ]

  type                      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name                      = "conn${module.openai.name}"
  parent_id                 = azapi_resource.workspace.id
  schema_validation_enabled = true

  body = {
    properties = {
      authType      = "AAD"
      category      = "AzureOpenAI"
      isSharedToAll = true
      target        = module.openai.endpoint
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-10-21"
        Location   = "eastus2"
        ResourceId = module.openai.id
      }
    }
  }
}

## Create a Private Endpoints for storage account and Key Vault
##
module "private_endpoint_st_aml_blob" {
  depends_on = [
    module.storage_account_aml_default,
    module.storage_account_data
  ]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.storage_account_aml_default.name
  resource_id      = module.storage_account_aml_default.id
  subresource_name = "blob"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  ]
}

module "private_endpoint_st_data_blob" {
  depends_on = [module.private_endpoint_st_aml_blob]

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

module "private_endpoint_st_aml_file" {
  depends_on = [module.private_endpoint_st_data_blob]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.storage_account_aml_default.name
  resource_id      = module.storage_account_aml_default.id
  subresource_name = "file"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  ]
}

module "private_endpoint_st_data_file" {
  depends_on = [module.private_endpoint_st_aml_file]

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

module "private_endpoint_st_aml_table" {
  depends_on = [module.private_endpoint_st_data_file]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.storage_account_aml_default.name
  resource_id      = module.storage_account_aml_default.id
  subresource_name = "table"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
  ]
}

module "private_endpoint_st_data_table" {
  depends_on = [module.private_endpoint_st_aml_table]

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

module "private_endpoint_st_aml_queue" {
  depends_on = [module.private_endpoint_st_data_table]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.storage_account_aml_default.name
  resource_id      = module.storage_account_aml_default.id
  subresource_name = "queue"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  ]
}

module "private_endpoint_st_data_queue" {
  depends_on = [module.private_endpoint_st_aml_queue]

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

module "private_endpoint_st_aml_dfs" {
  depends_on = [module.private_endpoint_st_data_queue]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.storage_account_aml_default.name
  resource_id      = module.storage_account_aml_default.id
  subresource_name = "dfs"

  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net"
  ]
}

module "private_endpoint_st_data_dfs" {
  depends_on = [module.private_endpoint_st_aml_dfs]

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

module "private_endpoint_kv" {
  depends_on = [module.private_endpoint_st_data_dfs]

  source              = "../../private-endpoint"
  random_string       = var.random_string
  location            = var.workload_vnet_location
  location_code       = var.workload_vnet_location_code
  resource_group_name = azurerm_resource_group.rgwork.name
  tags                = var.tags

  resource_name    = module.keyvault_aml.name
  resource_id      = module.keyvault_aml.id
  subresource_name = "vault"


  subnet_id = var.subnet_id
  private_dns_zone_ids = [
    "/subscriptions/${var.sub_id}/resourceGroups/${var.resource_group_name_dns}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  ]
}


