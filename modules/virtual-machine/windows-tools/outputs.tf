output "name" {
  value       = azurerm_windows_virtual_machine.vm.name
  description = "The name of the virtual machine"
}

output "id" {
  value       = azurerm_windows_virtual_machine.vm.id
  description = "The id of the virtual machine"
}