locals {
    # Standard naming convention for relevant resources
    law_prefix = "law"

    # Settings for Azure Key Vault
    sku_name = "premium"
    rbac_enabled = true
    deployment_vm = true
    deployment_template = true

    # Settings for Azure OpenAI
    openai_region = "East US 2"
    openai_region_code = "eus2"
}