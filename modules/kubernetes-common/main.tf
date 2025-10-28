terraform {
  required_providers {
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

variable "score_workload_resource_type" {
  type = string
}

locals {
  cluster_credentials_resource_id = "default"
  k8s_namespace_resource_id       = "env-specific"
}

resource "platform-orchestrator_resource_type" "k8s-namespace" {
  id          = "k8s-namespace"
  description = "A Kubernetes Namespace"
  output_schema = jsonencode({
    type     = "object"
    required = ["name"]
    properties = {
      name = {
        type        = "string"
        description = "The name of the Kubernetes namespace"
      }
    }
  })
  is_developer_accessible = true
}

resource "platform-orchestrator_resource_type" "k8s-service-account" {
  id          = "k8s-service-account"
  description = "A Kubernetes Service Account"
  output_schema = jsonencode({
    type     = "object"
    required = ["name", "namespace"]
    properties = {
      name = {
        type        = "string"
        description = "The name of the Kubernetes service account"
      }
      namespace = {
        type        = "string"
        description = "The name of the Kubernetes namespace"
      }
    }
  })
  is_developer_accessible = true
}

resource "platform-orchestrator_resource_type" "k8s-cluster-credentials" {
  id          = "k8s-cluster-credentials"
  description = "Access to a Kubernetes cluster"
  output_schema = jsonencode({
    type     = "object"
    required = ["host", "cluster_ca_certificate"]
    properties = {
      host = {
        type        = "string"
        description = "The endpoint of the Kubernetes cluster API server"
      }
      cluster_ca_certificate = {
        type        = "string"
        description = "The pem-encoded CA certificate data for the Kubernetes cluster"
      }
      token = {
        type        = "string"
        description = "Optional token of the service account"
      }
      client_key = {
        type        = "string"
        description = "Optional pem-encoded client certificate key for TLS authentication"
      }
      client_certificate = {
        type        = "string"
        description = "Optional pem-encoded client certificate for TLS authentication"
      }
    }
  })
  is_developer_accessible = false
}

resource "platform-orchestrator_resource_type" "aws-iam-role" {
  id          = "aws-iam-role"
  description = "Resource Type for AWS IAM role"
  output_schema = jsonencode({
    type     = "object"
    required = ["name", "arn"]
    properties = {
      name = {
        type        = "string"
        description = "IAM role name"
      }
      arn = {
        type        = "string"
        description = "IAM role arn"
      }
    }
  })
  is_developer_accessible = false
}

resource "platform-orchestrator_module" "k8s-namespace" {
  id                 = "k8s-namespace"
  resource_type      = platform-orchestrator_resource_type.k8s-namespace.id
  module_source      = "inline"
  module_source_code = <<EOT
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
variable "project" {
  type = string
}
variable "env_type_id" {
  type = string
}
resource "random_id" "r" {
  byte_length = 5
  prefix = "$${substr(var.project, 0, 30)}-$${substr(var.env_type_id, 0, 15)}-"
}
output "name" {
  value = random_id.r.hex
}
output "humanitec_metadata" {
  value = {
    "Kubernetes-Namespace" = random_id.r.hex,
    "Console-Url" = "https://headlamp.example.com/c/main/namespaces/$${random_id.r.hex}"
  }
}
EOT
  module_inputs = jsonencode({
    project     = "$${context.project_id}"
    env_type_id = "$${context.env_type_id}"
  })
  dependencies = {
    cluster_creds = {
      type = platform-orchestrator_resource_type.k8s-cluster-credentials.id
      id   = local.cluster_credentials_resource_id
    }
  }
}

resource "platform-orchestrator_module" "k8s-service-account" {
  id                 = "k8s-service-account"
  resource_type      = platform-orchestrator_resource_type.k8s-service-account.id
  module_source      = "inline"
  module_source_code = <<EOT
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
variable "namespace" {
  type = string
}
resource "random_id" "r" {
  byte_length = 5
  prefix = "score-workload-"
}
output "name" {
  value = random_id.r.hex
}
output "humanitec_metadata" {
  value = {
    "Kubernetes-Namespace" = var.namespace,
    "Kubernetes-Service-Account" = random_id.r.hex,
    "Console-Url" = "https://headlamp.example.com/c/main/serviceaccounts/$${var.namespace}/$${random_id.r.hex}"
  }
}
EOT
  module_inputs = jsonencode({
    namespace = "$${resources.namespace.outputs.name}"
  })
  dependencies = {
    cluster_creds = {
      type = platform-orchestrator_resource_type.k8s-cluster-credentials.id
      id   = local.cluster_credentials_resource_id
    }
    namespace = {
      type = platform-orchestrator_resource_type.k8s-namespace.id
      id   = local.k8s_namespace_resource_id
    }
  }
}

resource "platform-orchestrator_module" "k8s-score-workload" {
  id                 = "k8s-score-workload"
  resource_type      = var.score_workload_resource_type
  module_source      = "inline"
  module_source_code = <<EOT
variable "metadata" {
  type = map(any)
}
variable "containers" {
  type = map(any)
}
variable "service" {
  type = map(any)
  default = null
}
variable "namespace" {
  type = string
}
output "endpoint" {
  value = "$${var.metadata.name}.$${var.namespace}.svc.cluster.local"
}
output "humanitec_metadata" {
  value = {
    "Kubernetes-Namespace" = var.namespace,
    "Kubernetes-Deployment" = var.metadata.name,
    "Kubernetes-Service" = var.metadata.name,
    "Console-Url" = "https://headlamp.example.com/c/main/deployments/$${var.namespace}/$${var.metadata.name}"
  }
}
EOT
  module_inputs = jsonencode({
    namespace = "$${resources.namespace.outputs.name}"
  })
  module_params = {
    metadata = {
      type = "map"
    }
    containers = {
      type = "map"
    }
    service = {
      type        = "map"
      is_optional = true
    }
  }
  dependencies = {
    cluster_creds = {
      type = platform-orchestrator_resource_type.k8s-cluster-credentials.id
      id   = local.cluster_credentials_resource_id
    }
    namespace = {
      type = platform-orchestrator_resource_type.k8s-namespace.id
      id   = local.k8s_namespace_resource_id
    }
    service_account = {
      type = platform-orchestrator_resource_type.k8s-service-account.id
    }
  }
}

resource "platform-orchestrator_module_rule" "rules" {
  for_each = toset([
    platform-orchestrator_module.k8s-score-workload.id,
    platform-orchestrator_module.k8s-service-account.id,
  ])
  module_id = each.key
}

resource "platform-orchestrator_module_rule" "namespace" {
  module_id   = platform-orchestrator_module.k8s-namespace.id
  resource_id = local.k8s_namespace_resource_id
}

output "cluster_credentials_resource_type" {
  value = platform-orchestrator_resource_type.k8s-cluster-credentials.id
}

output "cluster_credentials_resource_id" {
  value = local.cluster_credentials_resource_id
}

output "namespace_resource_type" {
  value = platform-orchestrator_resource_type.k8s-namespace.id
}

output "namespace_resource_id" {
  value = local.k8s_namespace_resource_id
}
