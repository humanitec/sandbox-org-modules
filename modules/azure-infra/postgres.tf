resource "platform-orchestrator_module" "postgres" {
  id            = "azure-postgres"
  resource_type = var.postgres_resource_type
  module_source = "inline"
  module_inputs = jsonencode({
    env_type_id = "$${context.env_type_id}"
  })
  module_source_code = <<EOT
terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}
variable "env_type_id" {
  type = string
}
resource "random_id" "r" {
  byte_length = 3
}
locals {
  server_name = "$${var.env_type_id}-postgres-$${random_id.r.hex}"
  azure_region = "westeurope"
  resource_group = "rg-databases"
}
output "host" {
  value = "$${local.server_name}.postgres.database.azure.com"
}
output "port" {
  value = 5432
}
output "username" {
  value = "postgres@$${local.server_name}"
}
output "name" {
  value = "defaultdb"
}

output "humanitec_metadata" {
  value = {
    "Azure-Postgres-Server-Name" = local.server_name
    "Azure-Region" = local.azure_region
    "Azure-Resource-Group" = local.resource_group
    "Console-Url" = "https://portal.azure.com/#@/resource/subscriptions/my-subscription/resourceGroups/$${local.resource_group}/providers/Microsoft.DBforPostgreSQL/servers/$${local.server_name}"
  }
}
EOT
}

resource "platform-orchestrator_module_rule" "postgres" {
  module_id = platform-orchestrator_module.postgres.id
}