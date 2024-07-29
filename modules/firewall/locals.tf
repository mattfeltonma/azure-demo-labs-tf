locals {
  # Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Configure standard naming convention for relevant resources
  fw_name = "fw"
  fw_policy_name = "fp"
  ip_group_name = "ig"

  # Configure three character code for purpose of vnet
  fw_purpose = "cnt"
}
