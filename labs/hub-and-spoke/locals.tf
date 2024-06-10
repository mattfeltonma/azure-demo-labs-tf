locals {
  # Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Add required tags and merge them with the provided tags
  required_tags = {
    created_date  = timestamp()
    created_by    = data.azurerm_client_config.identity_config.object_id
  }

  tags = merge(
    var.tags,
    local.required_tags
  )
}
