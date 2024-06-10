locals {
    # Get first two characters of the location
    location_short = substr(var.location, 0, 2)

    # Standard naming convention for relevant resources
    kv_name = "kv"
    
    # Settings for Azure Key Vault
    sku_name = "premium"
    rbac_enabled = true
    deployment_vm = true
    deployment_template = true
}