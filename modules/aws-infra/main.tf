terraform {
  required_providers {
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

variable "cluster_credentials_resource_type" {
  type = string
}

resource "platform-orchestrator_module" "k8s-cluster-credentials" {
  id                 = "aws-k8s-cluster-credentials"
  resource_type      = var.cluster_credentials_resource_type
  module_source      = "inline"
  module_source_code = <<EOT
output "host" {
  value = "https://E0AB44F606B56BF1DAF47472A94746CB.yl4.eu-central-1.eks.amazonaws.com"
}
output "cluster_ca_certificate" {
  value = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWM..."
}
output "humanitec_metadata" {
  value = {
    "Aws-Ecs-Cluster-Name" = "example-cluster"
    "Aws-Region" = "eu-central-1"
  }
}
EOT
}
