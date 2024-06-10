resource "azurerm_vpn_site" "site" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  virtual_wan_id = var.vwan_id

  link {
    name       = "linkvpn${var.name}"
    ip_address = var.site_public_ip_address

    bgp {
      asn             = var.site_asn
      peering_address = var.site.bgp_ip_address
    }
  }


}
