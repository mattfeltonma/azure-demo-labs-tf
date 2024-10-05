resource "azapi_resource" "backend" {
  type                      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name                      = var.pool_name
  parent_id                 = var.apim_id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      description = "This is a load balanced pool for ${var.pool_name}"
      type        = "pool"
      pool = {
        services = var.backends
      }
    }
  })
}
