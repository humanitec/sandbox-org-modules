terraform {
  required_providers {
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

resource "platform-orchestrator_resource_type" "score-workload" {
  id          = "score-workload"
  description = "A Score Workload based application deployment"
  output_schema = jsonencode({
    type = "object"
    properties = {
      endpoint = {
        type        = "string"
        description = "An optional endpoint uri that the workload's service ports will be exposed on if any are defined"
      }
    }
  })
  is_developer_accessible = true
}

output "score_workload_resource_type" {
  value = platform-orchestrator_resource_type.score-workload.id
}
