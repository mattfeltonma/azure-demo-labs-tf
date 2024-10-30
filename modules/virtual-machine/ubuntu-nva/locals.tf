locals {
  # Configure standard naming convention for relevant resources
  vm_name = "vm"
  nic_name_int = "nici"
  nic_name_ext = "nice"

  # Network variables
  ip_configuration_name = "primary"
  ip_address_allocation = "Static"

  # Storage variables
  os_disk_name          = "mdos"
  os_disk_caching       = "ReadWrite"
  data_disk_name        = "mddata"
  data_disk_caching       = "ReadWrite"
  data_disk_lun         = 10

  # Extension variables
  custom_script_extension_version = "2.1"
  automatic_extension_ugprade = true
}
