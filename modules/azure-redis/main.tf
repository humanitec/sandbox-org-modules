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
  azure_region      = "westeurope"
  resource_group    = "my-resource-group"
  cache_name        = "my-${var.env_type_id}-redis-${random_id.r.hex}"
  subscription_id   = "00000000-0000-0000-0000-000000000000"
}

output "host" {
  value = "${local.cache_name}.redis.cache.windows.net"
}

output "port" {
  value = 6380
}

output "humanitec_metadata" {
  value = {
    "Azure-Region" : local.azure_region,
    "Azure-Resource-Group" : local.resource_group,
    "Azure-Cache-Name" : local.cache_name,
    "Console-Url" : "https://portal.azure.com/#@/resource/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group}/providers/Microsoft.Cache/redis/${local.cache_name}/overview",
  }
}
