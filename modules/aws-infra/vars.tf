terraform {
  required_providers {
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

variable "runtime" {
  type = string
}

variable "primary_resource" {
  type = string
}

variable "score_workload_resource_type" {
  type = string
}
