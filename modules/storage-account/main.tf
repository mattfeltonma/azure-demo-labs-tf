# Create a storage account
resource "azurerm_storage_account" "storage_account" {
  name                = "${local.storage_account_name}${var.purpose}${local.location_short}${var.random_string}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  account_kind             = var.storage_account_kind
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type


  network_rules {
    default_action = var.network_access_default
    bypass         = var.network_trusted_services_bypass
  }

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

# Configure diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "diag-base" {

  depends_on = [azurerm_storage_account.storage_account]

  name                       = "diag-base"
  target_resource_id         = azurerm_storage_account.storage_account.id
  log_analytics_workspace_id = var.law_resource_id

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-blob" {

  depends_on = [
    azurerm_storage_account.storage_account,
    azurerm_monitor_diagnostic_setting.diag-base]

  name                       = "diag-blob"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/blobServices/default"
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-file" {
  depends_on = [
    azurerm_storage_account.storage_account,
    azurerm_monitor_diagnostic_setting.diag-blob
  ]

  name                       = "diag-file"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/fileServices/default"
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-queue" {
  depends_on = [
    azurerm_storage_account.storage_account,
    azurerm_monitor_diagnostic_setting.diag-file
  ]

  name                       = "diag-default"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/queueServices/default"
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-table" {

  depends_on = [
    azurerm_storage_account.storage_account,
    azurerm_monitor_diagnostic_setting.diag-queue
  ]

  name                       = "diag-table"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/tableServices/default"
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}
