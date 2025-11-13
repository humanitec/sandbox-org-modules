resource "platform-orchestrator_module" "postgres" {
  id            = "cloudsql-postgres"
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
  instance_name = "$${var.env_type_id}-postgres-$${random_id.r.hex}"
  gcp_region = "europe-west1"
  gcp_project = "my-project-id"
}
output "host" {
  value = "$${local.instance_name}.c.$${local.gcp_project}.cloudsql.google.com"
}
output "port" {
  value = 5432
}
output "username" {
  value = "postgres"
}
output "name" {
  value = "postgres"
}

output "humanitec_metadata" {
  value = {
    "Gcp-CloudSql-Instance-Name" = local.instance_name
    "Gcp-Region" = local.gcp_region
    "Gcp-Project" = local.gcp_project
    "Console-Url" = "https://console.cloud.google.com/sql/instances/$${local.instance_name}/overview?project=$${local.gcp_project}"
  }
}
EOT
}

resource "platform-orchestrator_module_rule" "postgres" {
  module_id   = platform-orchestrator_module.postgres.id
}