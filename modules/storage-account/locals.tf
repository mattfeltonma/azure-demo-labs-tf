locals {
# Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Configure standard naming convention for relevant resources
  storage_account_name = "st"
}