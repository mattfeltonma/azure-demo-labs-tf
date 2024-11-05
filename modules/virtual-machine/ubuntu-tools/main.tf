resource "azurerm_network_interface" "nic" {
  name                = "${local.nic_name}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = local.ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.nic_private_ip_address
    public_ip_address_id          = var.public_ip_address_id
  }
  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.vm_name}${var.purpose}${var.location_code}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  size = var.vm_size
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  zone = var.availability_zone

  identity {
    type = var.identities != null ? var.identities.type : "SystemAssigned"
    identity_ids = var.identities != null ? var.identities.identity_ids : null
  }

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
  }

  os_disk {
    name = "${local.os_disk_name}${local.vm_name}${var.purpose}${var.location_code}${var.random_string}"

    storage_account_type = var.disk_os_storage_account_type
    disk_size_gb         = var.disk_os_size_gb
    caching              = local.os_disk_caching
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_managed_disk" "data" {
  name                 = "${local.data_disk_name}${local.vm_name}${var.purpose}${var.location_code}${var.random_string}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.disk_data_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.disk_data_size_gb

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-attach" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = local.data_disk_lun
  caching            = local.data_disk_caching
}

resource "azurerm_virtual_machine_extension" "custom-script-extension" {
  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]

  virtual_machine_id = azurerm_linux_virtual_machine.vm.id

  name                 = "custom-script-extension"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = local.custom_script_extension_version
  settings = jsonencode({
    commandToExecute = <<-EOT
      /bin/bash -c "echo '${replace(base64encode(file("${path.module}/../../../scripts/bootstrap-ubuntu-web.sh")), "'", "'\\''")}' | base64 -d > /tmp/bootstrap-ubuntu-web.sh && \
      chmod +x /tmp/bootstrap-ubuntu-web.sh && \
      /bin/bash /tmp/bootstrap-ubuntu-web.sh"
    EOT
  })

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dce_linux_tools" {
  depends_on = [
    azurerm_virtual_machine_extension.custom-script-extension
  ]

  name                        = "configurationAccessEndpoint"
  description                 = "Data Collection Endpoint Association for Linux NVA VM"
  data_collection_endpoint_id = var.dce_id
  target_resource_id          = azurerm_linux_virtual_machine.vm.id
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_linux_tools" {
  depends_on = [
    azurerm_monitor_data_collection_rule_association.dce_linux_tools
  ]

  name                    = "dcr${local.vm_name}${var.purpose}${var.location_code}${var.random_string}"
  description             = "Data Collection Rule Association for Linux NVA VM"
  data_collection_rule_id = var.dcr_id
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
}

resource "azurerm_virtual_machine_extension" "ama" {
  depends_on = [
    azurerm_monitor_data_collection_rule_association.dce_linux_tools,
    azurerm_monitor_data_collection_rule_association.dcr_linux_tools
  ]

  virtual_machine_id = azurerm_linux_virtual_machine.vm.id

  name                 = "AzureMonitorLinuxAgent"
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = local.monitor_agent_handler_version
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled = local.automatic_extension_ugprade

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}