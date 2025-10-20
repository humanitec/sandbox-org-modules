terraform {
  required_providers {
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

variable "inputs" {
  type = map(any)
}

resource "platform-orchestrator_resource_type" "test" {
  id = "test"
  output_schema = jsonencode({
    type = "object"
  })
}
