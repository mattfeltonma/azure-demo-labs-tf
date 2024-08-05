resource "azapi_resource" "backend" {
  type                      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  name                      = var.backend_name
  parent_id                 = var.apim_id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      circuitBreaker = {
        rules = [
          {
            failureCondition = {
              count = 1,
              errorReasons = [
                "The backend service is throttling"
              ],
              interval = "PT1M",
              statusCodeRanges = [
                {
                  max = 429
                  min = 429
                }
              ]
            }
            name             = "breakThrottling"
            tripDuration     = "PT1M"
            acceptRetryAfter = true
          }
        ]
      }
      description = "This is an API Management backend pool for resource ${var.backend_name}"
      type        = "single"
      protocol = "http"
      url         = var.url
    }
  })
}
