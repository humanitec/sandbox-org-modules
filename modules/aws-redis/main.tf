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
  aws_region   = "eu-central-1"
  cluster_name = "my-${var.env_type_id}-cluster${random_id.r.hex}"
}

output "host" {
  value = "${local.cluster_name}.${random_id.r.hex}.0001.euc1.cache.amazonaws.com"
}

output "port" {
  value = 6379
}

output "humanitec_metadata" {
  value = {
    "Aws-Region" : local.aws_region,
    "Aws-Elasticache-Cluster" : local.cluster_name,
    "Console-Url" : "https://${local.aws_region}.console.aws.amazon.com/elasticache/home?region=${local.aws_region}#redis-clusters/${local.cluster_name}",
    "Redis-Shard-Count" : var.env_type_id == "production" ? "6" : "1",
    "Redis-Instance-Type" : var.env_type_id == "production" ? "cache.m6g.large" : "cache.t3.micro",
  }
}
