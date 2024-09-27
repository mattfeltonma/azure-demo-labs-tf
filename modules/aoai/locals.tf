locals {
    # Get first two characters of the location
    location_short = substr(var.location, 0, 2)

    # Standard naming convention for relevant resources
    openai_name = "oai"

    # Settings for OpenAI Service
    sku_name = "S0"
    kind = "OpenAI"

}