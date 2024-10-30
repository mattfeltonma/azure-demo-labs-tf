output "backend_pool_id" {
  value       = azurerm_lb_backend_address_pool.pool.id
  description = "The ID of the backend address pool"
}

output "name" {
  value       = azurerm_lb.lb.name
  description = "The name of the load balancer"
}

output "id" {
  value       = azurerm_lb.lb.id
  description = "The id of the load balancer"
}

output "ip_address" {
  value       = azurerm_lb.lb.frontend_ip_configuration[0].private_ip_address
  description = "The private ip address of the load balancer"
}