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
  location_code_primary = lookup(local.region_abbreviations, var.location_primary, var.location_primary)
  location_code_secondary = var.multi_region == true ? try(
    lookup(local.region_abbreviations, var.location_secondary, var.location_secondary),
    null
  ) : null

  # Naming conventions
  route_prefix = "udr"

  # Fixed variables
  law_purpose = "cnt"

  # Create the virtual network cidr ranges
  vnet_cidr_tr_pri = cidrsubnet(var.address_space_azure_primary_region, 2, 0)
  vnet_cidr_ss_pri = cidrsubnet(var.address_space_azure_primary_region, 2, 1)
  vnet_cidr_wl_pri = cidrsubnet(var.address_space_azure_primary_region, 2, 2)
  primary_region_vnet_cidrs = {
    "ss" = local.vnet_cidr_ss_pri,
    "wl" = local.vnet_cidr_wl_pri
  }

  vnet_cidr_tr_sec = var.multi_region == true ? try(cidrsubnet(var.address_space_azure_secondary_region, 2, 0), null) : null
  vnet_cidr_ss_sec = var.multi_region == true ? try(cidrsubnet(var.address_space_azure_secondary_region, 2, 1), null) : null
  vnet_cidr_wl_sec = var.multi_region == true ? try(cidrsubnet(var.address_space_azure_secondary_region, 2, 2), null) : null
  secondary_region_vnet_cidrs = var.multi_region == true ? {
    "ss" = local.vnet_cidr_ss_sec,
    "wl" = local.vnet_cidr_wl_sec
  } : {}

  # Add required tags and merge them with the provided tags
  required_tags = {
    created_date = timestamp()
    created_by   = data.azurerm_client_config.identity_config.object_id
  }

  # Regionally specific Private DNS Zones
  # Construct regional Private DNS Zones
  aks_private_dns_namespace_primary   = "privatelink.${var.location_primary}.azmk8s.io"
  aks_private_dns_namespace_secondary = var.multi_region == true ? ["privatelink.${var.location_secondary}.azmk8s.io"] : []

  # Add regional zones to a list 
  regional_private_dns_namespaces = concat(
    [
      local.aks_private_dns_namespace_primary
    ],
    local.aks_private_dns_namespace_secondary
  )

  private_dns_namespaces_with_regional_zones = concat(var.private_dns_namespaces, local.regional_private_dns_namespaces)

  tags = merge(
    var.tags,
    local.required_tags
  )
}
