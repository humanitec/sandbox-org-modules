module "k8s-common" {
  source                       = "../kubernetes-common"
  for_each                     = toset(var.runtime == "kubernetes" ? ["this"] : [])
  score_workload_resource_type = var.score_workload_resource_type
}

resource "platform-orchestrator_module" "k8s-cluster-credentials" {
  for_each      = toset(var.runtime == "kubernetes" ? ["this"] : [])
  id            = "gcp-k8s-cluster-credentials"
  resource_type = module.k8s-common["this"].cluster_credentials_resource_type
  module_source = "inline"
  module_inputs = jsonencode({
    env_type_id = "$${context.env_type_id}"
  })
  module_source_code = <<EOT
variable "env_type_id" {
  type = string
}
output "host" {
  value = "https://34.75.145.245"
}
output "cluster_ca_certificate" {
  value = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWM..."
}
locals {
  cluster_project = "example-project"
  cluster_region = "europe-west3"
  cluster_name = lookup({"production": "production-cluster"}, var.env_type_id, "development_cluster")
}

output "humanitec_metadata" {
  value = {
    "Gcp-Project" = local.cluster_project
    "Gcp-Gke-Cluster-Name" = local.cluster_name
    "Gcp-Region" = local.cluster_region
    "Console-Url" = "https://console.cloud.google.com/kubernetes/clusters/details/$${local.cluster_region}/$${local.cluster_name}/overview?hl=en&project=$${local.cluster_project}"
  }
}
EOT
}

resource "platform-orchestrator_module_rule" "cluster-creds" {
  for_each    = toset(var.runtime == "kubernetes" ? ["this"] : [])
  module_id   = platform-orchestrator_module.k8s-cluster-credentials["this"].id
  resource_id = module.k8s-common["this"].cluster_credentials_resource_id
}
