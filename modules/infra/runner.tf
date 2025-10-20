variable "runner_config" {
  type = object({
    region                     = string
    subnet_ids                 = list(string)
    security_group_ids         = list(string)
    humanitec_org_id           = string
    existing_ecs_cluster_name = string
    existing_oidc_provider_arn = string
  })
}

module "ecs_runner" {
  source = "github.com/humanitec/reusable-platform-orchestrator-ecs-runner"

  runner_id_prefix           = "ecs-runner"
  region                     = var.runner_config.region
  subnet_ids                 = var.runner_config.subnet_ids
  security_group_ids         = var.runner_config.security_group_ids
  humanitec_org_id           = var.runner_config.humanitec_org_id
  existing_ecs_cluster_name = var.runner_config.existing_ecs_cluster_name
  existing_oidc_provider_arn = var.runner_config.existing_oidc_provider_arn
}

resource "platform-orchestrator_runner_rule" "default" {
  runner_id = module.ecs_runner.runner_id
}
