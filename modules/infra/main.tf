terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

variable "inputs" {
  type = object({
    cloud = string
  })
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
  }
}
EOT
  module_inputs = jsonencode({
    namespace = "$${resources.namespace.outputs.name}"
  })
  dependencies = {
    cluster_creds = {
      type = platform-orchestrator_resource_type.k8s-cluster-credentials.id
    }
    namespace = {
      type = platform-orchestrator_resource_type.k8s-namespace.id
    }
  }
}

resource "platform-orchestrator_module" "k8s-score-workload" {
  id                 = "k8s-score-workload"
  resource_type      = platform-orchestrator_resource_type.score-workload.id
  module_source      = "inline"
  module_source_code = <<EOT
variable "metadata" {
  type = object({
    name = string
    annotations = any
  })
}
variable "containers" {
  type = any
}
variable "service" {
  type = any
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
  }
}
EOT
  module_inputs = jsonencode({
    namespace = "$${resources.namespace.outputs.name}"
  })
  dependencies = {
    cluster_creds = {
      type = platform-orchestrator_resource_type.k8s-cluster-credentials.id
    }
    namespace = {
      type = platform-orchestrator_resource_type.k8s-namespace.id
    }
    service_account = {
      type = platform-orchestrator_resource_type.k8s-service-account.id
    }
  }
}

locals {
  is_aws = var.inputs.cloud == "aws"
}

module "aws-infra" {
  source                            = "github.com/humanitec/sandbox-org-modules//modules/aws-infra?ref=setup-aws-kubernetes-modules"
  for_each                          = toset(local.is_aws ? ["this"] : [])
  cluster_credentials_resource_type = platform-orchestrator_resource_type.k8s-cluster-credentials.id
}
