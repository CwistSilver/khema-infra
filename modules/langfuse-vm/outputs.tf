output "resource_group_name" {
  description = "Name of the Langfuse resource group"
  value       = azurerm_resource_group.langfuse.name
}

output "vm_name" {
  description = "Name of the VM"
  value       = azurerm_linux_virtual_machine.langfuse.name
}

output "vm_id" {
  description = "ID of the VM"
  value       = azurerm_linux_virtual_machine.langfuse.id
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.langfuse.ip_address
}

output "langfuse_url" {
  description = "URL to access Langfuse"
  value       = "http://${azurerm_public_ip.langfuse.ip_address}:3000"
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.langfuse.ip_address}"
}

output "docker_logs_command" {
  description = "Command to view Langfuse logs"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.langfuse.ip_address} 'cd /opt/langfuse && docker compose logs -f'"
}
