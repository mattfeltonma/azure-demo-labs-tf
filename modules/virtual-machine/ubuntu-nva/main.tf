## Create public IP address to be used by public NIC
##
module "public-ip" {
  source              = "../../public-ip"
  random_string       = var.random_string
  location            = var.location
  location_code       = var.location_code
  resource_group_name = var.resource_group_name

  law_resource_id = var.law_resource_id

  purpose = var.purpose
  tags    = var.tags
}

## Create private and public NICs and associate them with load balancer backend pools
##
resource "azurerm_network_interface" "public-nic" {
  depends_on = [
    module.public-ip
  ]

  name                  = "${local.nic_name_ext}${var.purpose}${var.location_code}${var.random_string}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true
  ip_configuration {
    name                          = local.ip_configuration_name
    subnet_id                     = var.subnet_id_public
    private_ip_address_allocation = local.ip_address_allocation
    private_ip_address            = var.nic_public_private_ip_address
    public_ip_address_id          = module.public-ip.id
  }
  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "public-nic-pool" {
  depends_on = [
    azurerm_network_interface.private-nic
  ]

  network_interface_id    = azurerm_network_interface.public-nic.id
  ip_configuration_name   = local.ip_configuration_name
  backend_address_pool_id = var.be_address_pool_pub_id
}

resource "azurerm_network_interface" "private-nic" {
  name                  = "${local.nic_name_int}${var.purpose}${var.location_code}${var.random_string}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  ip_forwarding_enabled = true
  ip_configuration {
    name                          = local.ip_configuration_name
    subnet_id                     = var.subnet_id_private
    private_ip_address_allocation = local.ip_address_allocation
    private_ip_address            = var.nic_private_private_ip_address
  }
  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      tags["created_by"]
    ]
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "private-nic-pool" {
  depends_on = [
    azurerm_network_interface.private-nic
  ]

  network_interface_id    = azurerm_network_interface.private-nic.id
  ip_configuration_name   = local.ip_configuration_name
  backend_address_pool_id = var.be_address_pool_priv_id
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
    azurerm_network_interface.public-nic.id,
    azurerm_network_interface.private-nic.id
  ]
  zone = var.availability_zone

  dynamic "identity" {
    for_each = var.identities != null ? [var.identities] : []
    content {
      type         = var.identities.type
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
    name                 = "${local.os_disk_name}${local.vm_name}${var.purpose}${var.location_code}${var.random_string}"
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
      /bin/bash -c "echo '${replace(base64encode(file("${path.module}/../../../scripts/bootstrap-ubuntu-nva.sh")), "'", "'\\''")}' | base64 -d > /tmp/bootstrap-ubuntu-nva.sh && \
      chmod +x /tmp/bootstrap-ubuntu-nva.sh && \
      /bin/bash /tmp/bootstrap-ubuntu-nva.sh \
      --hostname '${local.vm_name}${var.purpose}${var.location_code}${var.random_string}' \
      --router_asn '${var.asn_router}' \
      --nva_private_ip '${var.nic_private_private_ip_address}' \
      --public_nic_gateway_ip '${var.ip_outer_gateway}' \
      --private_nic_gateway_ip '${var.ip_inner_gateway}'"
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
