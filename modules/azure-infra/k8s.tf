module "k8s-common" {
  source                       = "github.com/humanitec/sandbox-org-modules//modules/kubernetes-common?ref=setup-aws-kubernetes-modules"
  for_each                     = toset(var.runtime == "kubernetes" ? ["this"] : [])
  score_workload_resource_type = var.score_workload_resource_type
}

resource "platform-orchestrator_module" "k8s-cluster-credentials" {
  id            = "azure-k8s-cluster-credentials"
  resource_type = module.k8s-common.cluster_credentials_resource_type
  module_source = "inline"
  module_inputs = jsonencode({
    env_type_id = "$${context.env_type_id}"
  })
  module_source_code = <<EOT
variable "env_type_id" {
  type = string
}
output "host" {
  value = "https://azure-cluster-1a2b3c4d.hcp.eastus.azmk8s.io:443"
}
output "cluster_ca_certificate" {
  value = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWM..."
}
locals {
  cluster_project = "example-project"
  cluster_region = "eastus"
  cluster_name = lookup({"production": "aks-production-cluster"}, var.env_type_id, "aks-development_cluster")
}

output "humanitec_metadata" {
  value = {
    "Azure-Resource-Group" = local.cluster_project
    "Azure-Aks-Cluster-Name" = local.cluster_name
    "Azure-Region" = local.cluster_region
    "Console-Url" = "https://portal.azure.com/#@some-tenant/resource/subscriptions/some-subscription/resourceGroups/$${local.cluster_project}/providers/Microsoft.ContainerService/managedClusters/$${local.cluster_name}/overview"
  }
}
EOT
}

resource "platform-orchestrator_module_rule" "cluster-creds" {
  module_id   = platform-orchestrator_module.k8s-cluster-credentials.id
  resource_id = module.k8s-common.cluster_credentials_resource_id
}
