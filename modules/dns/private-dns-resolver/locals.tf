locals {
    # Get first two characters of the location
    location_short = substr(var.location, 0, 2)

    # Standard naming convention for relevant Azure resources
    private_resolver_name = "pdnsresolv"
    private_resolver_inbound_endpoint = "dnsrin"
    private_resolver_outbound_endpoint = "dnsrout"
}