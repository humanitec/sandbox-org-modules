resource "platform-orchestrator_project" "project" {
  id = "example"
}

resource "platform-orchestrator_environment" "development" {
  id          = "development"
  project_id  = platform-orchestrator_project.project.id
  env_type_id = platform-orchestrator_environment_type.development.id
  depends_on  = [platform-orchestrator_runner_rule.default]
}
