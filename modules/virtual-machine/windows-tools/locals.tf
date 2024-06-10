locals {
  # Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Configure standard naming convention for relevant resources
  vm_name = "vm"
  nic_name = "nic"

  # Network variables
  ip_configuration_name = "primary"

  # Storage variables
  os_disk_name          = "mdos"
  os_disk_caching       = "ReadWrite"
  data_disk_name        = "mddata"
  data_disk_caching       = "ReadWrite"
  data_disk_lun         = 10

  # Extension variables
  custom_script_extension_version = "1.10"
  monitor_agent_handler_version = "1.0"
  automatic_extension_ugprade = true
}
