locals {
    # Standard naming convention for relevant resources
    app_insights_prefix = "appin"
    ai_foundry_hub_prefix = "aifh"
    ai_foundry_project_prefix = "aifp"
    umi_prefix = "umi"

    # Settings for Azure Key Vault
    sku_name = "premium"
    rbac_enabled = true
    deployment_vm = true
    deployment_template = true

    # Settings for Azure OpenAI
    openai_region = "East US 2"
    openai_region_code = "eus2"
}