locals {
    # Standard naming convention for relevant resources
    kv_name = "kv"

    # Settings for Azure Key Vault
    sku_name = "premium"
    rbac_enabled = true
    deployment_vm = true
    deployment_template = true
}