output "shared_resources" {
  description = "Shared resources information"
  value = {
    resource_group_name             = module.shared_resources.resource_group_name
    postgresql_server_name          = module.shared_resources.postgresql_server_name
    postgresql_server_fqdn          = module.shared_resources.postgresql_server_fqdn
    key_vault_name                  = module.shared_resources.key_vault_name
    key_vault_uri                   = module.shared_resources.key_vault_uri
    container_registry_name         = module.shared_resources.container_registry_name
    container_registry_login_server = module.shared_resources.container_registry_login_server
  }
}

output "langfuse" {
  description = "Langfuse deployment information"
  value = {
    resource_group_name = module.langfuse.resource_group_name
    vm_name             = module.langfuse.vm_name
    public_ip_address   = module.langfuse.public_ip_address
    langfuse_url        = module.langfuse.langfuse_url
    ssh_command         = module.langfuse.ssh_command
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT

  ============================================
  Deployment Complete!
  ============================================

  Langfuse Web UI: ${module.langfuse.langfuse_url}

  Wait 2-3 minutes for all services to start, then:
  1. Open ${module.langfuse.langfuse_url} in your browser
  2. Create your first admin account
  3. Start using Langfuse!

  SSH Access: ${module.langfuse.ssh_command}

  View logs: ${module.langfuse.docker_logs_command}

  Shared Resources:
  - PostgreSQL: ${module.shared_resources.postgresql_server_fqdn}
  - Key Vault: ${module.shared_resources.key_vault_name}
  - Container Registry: ${module.shared_resources.container_registry_login_server}

  Estimated Monthly Cost: ~48€
  - PostgreSQL (B1ms): ~18€
  - VM (B2s): ~30€
  - Storage & misc: ~1€

  ============================================
  EOT
}
