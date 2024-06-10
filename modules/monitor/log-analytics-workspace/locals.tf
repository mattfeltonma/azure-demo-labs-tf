locals {
# Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Configure standard naming convention for relevant resources
  nsg_name = "law"


  # Log Analytics Workspace SKU
  log_analytics_sku = "PerGB2018"
}