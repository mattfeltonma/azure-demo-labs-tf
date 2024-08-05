locals {
  # Get first two characters of the location
  location_short = substr(var.location, 0, 2)

  # Regionally specific Private DNS Zones
  aks_private_dns_namespace = "privatelink.${var.location}.azmk8s.io"
  regional_private_dns_namespaces = [
    local.aks_private_dns_namespace
  ]
  private_dns_namespaces_with_regional_zones = concat(var.private_dns_namespaces, local.regional_private_dns_namespaces)

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
