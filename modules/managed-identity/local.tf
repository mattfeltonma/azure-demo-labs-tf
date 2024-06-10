locals {
    # Get first two characters of the location
    location_short = substr(var.location, 0, 2)

    # Standard naming convention for relevant resources
    umi_name = "umi"
}