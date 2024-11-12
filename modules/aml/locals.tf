locals {
    # Standard naming convention for relevant resources
    kv_name = "aml"
    app_insights_name = "appin"

    # Settings for Azure Key Vault
    sku_name = "premium"
    rbac_enabled = true
    deployment_vm = true
    deployment_template = true
}