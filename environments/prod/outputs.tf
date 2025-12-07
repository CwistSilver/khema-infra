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
  value       = azurerm_resource_group.prod.name
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT

  Production Deployment completed successfully!

  Application URL: ${module.langfuse.langfuse_web_url}

  Database: ${module.langfuse.database_name}
  Redis: ${module.langfuse.redis_hostname}
  Storage: ${module.langfuse.storage_account_name}

  IMPORTANT:
  - Update your DNS to point to: ${module.langfuse.langfuse_web_fqdn}
  - Configure SSL certificates if using custom domain
  - Set up monitoring and alerts
  - Review security settings
  EOT
}
