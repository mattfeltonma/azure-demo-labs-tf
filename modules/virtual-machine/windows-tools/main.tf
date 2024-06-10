resource "azurerm_network_interface" "nic" {
  name                = "${local.nic_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = local.ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
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

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${local.vm_name}${var.purpose}${local.location_short}${var.random_string}"
  location            = var.location
  resource_group_name = var.resource_group_name

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password

  size = var.vm_size
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  zone = var.availability_zone

  dynamic identity {
    for_each = var.identities != null ? [var.identities] : []
    content {
      type = var.identities.type
      identity_ids = var.identities.identity_ids
    }
  }

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
  }

  os_disk {
    name                 = "${local.os_disk_name}${local.vm_name}${var.purpose}${local.location_short}${var.random_string}"
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
  name                 = "${local.data_disk_name}${local.vm_name}${var.purpose}${local.location_short}${var.random_string}"
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
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = local.data_disk_lun
  caching            = local.data_disk_caching
}

resource "azurerm_virtual_machine_extension" "ama" {
  depends_on = [
    azurerm_windows_virtual_machine.vm,
    azurerm_virtual_machine_data_disk_attachment.data-attach
  ]

  virtual_machine_id = azurerm_windows_virtual_machine.vm.id

  name                 = "AzureMonitorWindowsAgent"
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = local.monitor_agent_handler_version

  automatic_upgrade_enabled = local.automatic_extension_ugprade

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_virtual_machine_extension" "custom-script-extension" {
  depends_on = [
    azurerm_virtual_machine_extension.ama,
    azurerm_windows_virtual_machine.vm
  ]

  virtual_machine_id = azurerm_windows_virtual_machine.vm.id

  name                 = "custom-script-extension"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = local.custom_script_extension_version
  protected_settings   = <<SETTINGS
  {
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted -EncodedCommand ${textencodebase64(file("${path.module}/../../../scripts/bootstrap-windows-tool.ps1"), "UTF-16LE")}" 
  }
  SETTINGS

  # Adjust timeout because provisioning script can take a fair amount of time
  timeouts {
    create = "60m"
    update = "60m"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}
