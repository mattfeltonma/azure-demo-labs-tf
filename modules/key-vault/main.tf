resource "azurerm_key_vault" "kv" {
  name                = "${local.kv_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name  = local.sku_name
  tenant_id = data.azurerm_subscription.current.tenant_id

  enabled_for_deployment          = local.deployment_vm
  enabled_for_template_deployment = local.deployment_template
  enable_rbac_authorization       = local.rbac_enabled

  enabled_for_disk_encryption = var.disk_encryption
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_role_assignment" "assign-admin" {
  depends_on = [ 
    azurerm_key_vault.kv 
  ]
  name                 = uuidv5("dns", "${azurerm_key_vault.kv.name}${var.kv_admin_object_id}")
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.KeyVault/vaults/${azurerm_key_vault.kv.name}"
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.kv_admin_object_id
}

resource "azurerm_monitor_diagnostic_setting" "diag-base" {
  depends_on = [ 
    azurerm_key_vault.kv,
    azurerm_role_assignment.assign-admin
  ]

  name                       = "diag-base"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.law_resource_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}
