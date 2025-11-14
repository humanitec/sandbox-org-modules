terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_id" "r" {
  byte_length = 3
}

variable "env_type_id" {
  type = string
}

locals {
  gcp_region    = "europe-west1"
  gcp_project   = "my-project-id"
  instance_name = "my-${var.env_type_id}-redis-${random_id.r.hex}"
}

output "host" {
  value = "${local.instance_name}.${random_id.r.hex}.c.${local.gcp_project}.internal"
}

output "port" {
  value = 6379
}

output "humanitec_metadata" {
  value = {
    "Gcp-Region" : local.gcp_region,
    "Gcp-Project" : local.gcp_project,
    "Gcp-Memorystore-Instance" : local.instance_name,
    "Console-Url" : "https://console.cloud.google.com/memorystore/redis/locations/${local.gcp_region}/instances/${local.instance_name}?project=${local.gcp_project}",
  }
}
