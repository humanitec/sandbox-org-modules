terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    platform-orchestrator = {
      source  = "humanitec/platform-orchestrator"
      version = ">= 2.10"
    }
  }
}

variable "inputs" {
  type = object({
    cloud            = string
    runtime          = string
    primary_resource = string
  })

  validation {
    condition     = contains(["aws", "gcp", "azure"], var.inputs.cloud)
    error_message = "Invalid cloud: Must be one of [\"aws\", \"gcp\", \"azure\"]."
  }

  validation {
    condition     = contains(["kubernetes", "vms", "serverless"], var.inputs.runtime)
    error_message = "Invalid runtime: Must be one of [\"kubernetes\", \"vms\", \"serverless\"]."
  }

  validation {
    condition     = contains(["postgres", "redis"], var.inputs.primary_resource)
    error_message = "Invalid primary_resource: Must be one of [\"postgres\", \"redis\"]."
  }
}

resource "platform-orchestrator_environment_type" "development" {
  id           = "development"
  display_name = "Development"
}

resource "platform-orchestrator_environment_type" "production" {
  id           = "production"
  display_name = "Production"
}

module "score-common" {
  source = "../score-common"
}

module "aws-infra" {
  source                       = "../aws-infra"
  for_each                     = toset(var.inputs.cloud == "aws" ? ["this"] : [])
  runtime                      = var.inputs.runtime
  primary_resource             = var.inputs.primary_resource
  score_workload_resource_type = module.score-common.score_workload_resource_type
  depends_on                   = [platform-orchestrator_environment_type.development, platform-orchestrator_environment_type.production]
}

module "gcp-infra" {
  source                       = "../gcp-infra"
  for_each                     = toset(var.inputs.cloud == "gcp" ? ["this"] : [])
  runtime                      = var.inputs.runtime
  primary_resource             = var.inputs.primary_resource
  score_workload_resource_type = module.score-common.score_workload_resource_type
  depends_on                   = [platform-orchestrator_environment_type.development, platform-orchestrator_environment_type.production]
}

module "azure-infra" {
  source                       = "../azure-infra"
  for_each                     = toset(var.inputs.cloud == "azure" ? ["this"] : [])
  runtime                      = var.inputs.runtime
  primary_resource             = var.inputs.primary_resource
  score_workload_resource_type = module.score-common.score_workload_resource_type
  depends_on                   = [platform-orchestrator_environment_type.development, platform-orchestrator_environment_type.production]
}
