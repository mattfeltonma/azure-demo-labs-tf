locals {
  # Convert the region name to a unique abbreviation
  region_abbreviations = {
    "australiacentral"   = "acl",
    "australiacentral2"  = "acl2",
    "australiaeast"      = "ae",
    "australiasoutheast" = "ase",
    "brazilsouth"        = "brs",
    "brazilsoutheast"    = "bse",
    "canadacentral"      = "cnc",
    "canadaeast"         = "cne",
    "centralindia"       = "ci",
    "centralus"          = "cus",
    "centraluseuap"      = "ccy",
    "eastasia"           = "ea",
    "eastus"             = "eus",
    "eastus2"            = "eus2",
    "eastus2euap"        = "ecy",
    "francecentral"      = "frc",
    "francesouth"        = "frs",
    "germanynorth"       = "gn",
    "germanywestcentral" = "gwc",
    "israelcentral"      = "ilc",
    "italynorth"         = "itn",
    "japaneast"          = "jpe",
    "japanwest"          = "jpw",
    "jioindiacentral"    = "jic",
    "jioindiawest"       = "jiw",
    "koreacentral"       = "krc",
    "koreasouth"         = "krs",
    "mexicocentral"      = "mxc",
    "northcentralus"     = "ncus",
    "northeurope"        = "ne",
    "norwayeast"         = "nwe",
    "norwaywest"         = "nww",
    "polandcentral"      = "plc",
    "qatarcentral"       = "qac",
    "southafricanorth"   = "san",
    "southafricawest"    = "saw",
    "southcentralus"     = "scus",
    "southeastasia"      = "sea",
    "southindia"         = "si",
    "spaincentral"       = "spac"
    "swedencentral"      = "swc",
    "switzerlandnorth"   = "swn",
    "switzerlandwest"    = "sww",
    "uaecentral"         = "uaec",
    "uaenorth"           = "uaen",
    "uksouth"            = "uks",
    "ukwest"             = "ukw",
    "westcentralus"      = "wcus",
    "westeurope"         = "we",
    "westindia"          = "wi",
    "westus"             = "wus",
    "westus2"            = "wus2",
    "westus3"            = "wus3"
  }

  location_short = lookup(local.region_abbreviations, var.location, var.location)

  # Create the virtual network cidr ranges
  vnet_cidr_tr = cidrsubnet(var.address_space_azure_region, 2, 0)
  vnet_cidr_ss = cidrsubnet(var.address_space_azure_region, 2, 1)
  vnet_cidr_wl = cidrsubnet(var.address_space_azure_region, 2, 2)

  # Add required tags and merge them with the provided tags
  required_tags = {
    created_date  = timestamp()
    created_by    = data.azurerm_client_config.identity_config.object_id
  }

  # Regionally specific Private DNS Zones
  aks_private_dns_namespace = "privatelink.${var.location}.azmk8s.io"
  regional_private_dns_namespaces = [
    local.aks_private_dns_namespace
  ]
  private_dns_namespaces_with_regional_zones = concat(var.private_dns_namespaces, local.regional_private_dns_namespaces)

  tags = merge(
    var.tags,
    local.required_tags
  )
}
