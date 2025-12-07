output "langfuse_web_url" {
  description = "URL of the Langfuse web application"
  value       = "https://${azurerm_container_app.langfuse_web.ingress[0].fqdn}"
}

output "langfuse_web_fqdn" {
  description = "FQDN of the Langfuse web application"
  value       = azurerm_container_app.langfuse_web.ingress[0].fqdn
}

output "container_app_web_id" {
  description = "ID of the Langfuse web container app"
  value       = azurerm_container_app.langfuse_web.id
}

output "container_app_worker_id" {
  description = "ID of the Langfuse worker container app"
  value       = azurerm_container_app.langfuse_worker.id
}

output "redis_hostname" {
  description = "Hostname of the Redis cache"
  value       = azurerm_redis_cache.langfuse.hostname
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.langfuse.name
}

output "database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.langfuse.name
}
