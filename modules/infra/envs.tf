resource "platform-orchestrator_project" "project" {
  id = "example"
}

resource "platform-orchestrator_environment" "development" {
  id          = "development"
  project_id  = platform-orchestrator_project.project.id
  env_type_id = platform-orchestrator_environment_type.development.id
  depends_on  = [platform-orchestrator_runner_rule.default]
}

# The ECS runner's IAM policies take a little time to be effective. We need to sleep a little extra until it's effective.
resource "terraform_data" "sleepy" {
  provisioner "local-exec" {
    command = "sleep 20"
  }
  depends_on = [platform-orchestrator_runner_rule.default]
}

resource "platform-orchestrator_deployment" "deploy" {
  project_id = platform-orchestrator_project.project.id
  env_id     = platform-orchestrator_environment.development.id
  manifest = jsonencode({
    workloads = {
      todo-app = {
        resources = {
          score-workload = {
            type = "score-workload"
            params = {
              metadata = {
                name = "todo-app"
              }
              containers = {
                main = {
                  image = "ghcr.io/humanitec/todo-app:latest"
                }
                variables = {
                  DB_HOST = "$${resources.database.outputs.host}"
                  DB_PORT = "$${resources.database.outputs.port}"
                  DB_NAME = "$${resources.database.outputs.name}"
                  DB_USER = "$${resources.database.outputs.username}"
                }
              }
            }
          }
          database = {
            type = "postgres"
          }
        }
      }
    }
  })

  wait_for = false

  depends_on = [
    module.aws-infra,
    module.gcp-infra,
    module.azure-infra,
    terraform_data.sleepy,
  ]
}
