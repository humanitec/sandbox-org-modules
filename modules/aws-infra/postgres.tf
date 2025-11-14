resource "platform-orchestrator_module" "postgres" {
  id            = "rds-postgres"
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
  db_name = "$${var.env_type_id}-database-$${random_id.r.hex}"
  aws_region = "eu-central-1"
}
output "host" {
  value = "$${local.db_name}.012345.$${local.aws_region}.rds.amazonaws.com"
}
output "port" {
  value = 5432
}
output "username" {
  value = "postgres"
}
output "name" {
  value = "default"
}

output "humanitec_metadata" {
  value = {
    "Aws-Rds-Name" = local.db_name
    "Aws-Region" = local.aws_region
    "Console-Url" = "https://$${local.aws_region}.console.aws.amazon.com/rds/home?region=$${local.aws_region}#database:id=$${local.db_name}"
  }
}
EOT
}

resource "platform-orchestrator_module_rule" "postgres" {
  module_id = platform-orchestrator_module.postgres.id
}
