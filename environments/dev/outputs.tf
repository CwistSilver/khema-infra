output "langfuse_web_url" {
  description = "URL of the Langfuse web application"
  value       = module.langfuse.langfuse_web_url
}

output "langfuse_web_fqdn" {
  description = "FQDN of the Langfuse web application"
  value       = module.langfuse.langfuse_web_fqdn
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.dev.name
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT

  Deployment completed successfully!

  Next steps:
  1. Access Langfuse at: ${module.langfuse.langfuse_web_url}
  2. Create your first admin account
  3. Update terraform.tfvars with the nextauth_url: ${module.langfuse.langfuse_web_url}
  4. Re-apply to update the NextAuth configuration

  Database: ${module.langfuse.database_name}
  Redis: ${module.langfuse.redis_hostname}
  Storage: ${module.langfuse.storage_account_name}
  EOT
}
