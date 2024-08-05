variable "apim_id" {
  description = "The resource id of the API Management instance"
  type        = string
}

variable "backends" {
  description = "The list of backends"
  type = list(object({
    id       = string
    priority = number
  }))
}

variable "pool_name" {
  description = "The name of the backend"
  type        = string
}