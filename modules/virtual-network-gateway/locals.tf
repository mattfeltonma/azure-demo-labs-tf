locals {
  # Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Configure standard naming convention for relevant resources
  vng_name = "vng"
  pip_name= "pip"

  # Virtual Network Gateway configuration
  vng_type = "Vpn"
  vpn_type = "RouteBased"
}
