locals {
    # Get first two characters of the location
    location_short = substr(var.location, 0, 2)

    # Standard naming convention for relevant resources
    pe_name = "pe"
    pe_nic_name = "nicpe"
    pe_conn_name ="pec"
    pe_zone_group_conn_name = "pezgc"
}