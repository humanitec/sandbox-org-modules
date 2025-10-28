module "k8s-common" {
  source                       = "../kubernetes-common"
  for_each                     = toset(var.runtime == "kubernetes" ? ["this"] : [])
  score_workload_resource_type = var.score_workload_resource_type
}

resource "platform-orchestrator_module" "k8s-cluster-credentials" {
  for_each      = toset(var.runtime == "kubernetes" ? ["this"] : [])
  id            = "aws-k8s-cluster-credentials"
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
  value = "https://E0AB44F606B56BF1DAF47472A94746CB.yl4.eu-central-1.eks.amazonaws.com"
}
output "cluster_ca_certificate" {
  value = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWM..."
}
locals {
  cluster_region = "eu-central-1"
  cluster_name = lookup({"production": "production-cluster"}, var.env_type_id, "development_cluster")
}

output "humanitec_metadata" {
  value = {
    "Aws-Ecs-Cluster-Name" = local.cluster_name
    "Aws-Region" = local.cluster_region
    "Console-Url" = "https://$${local.cluster_region}.console.aws.amazon.com/eks/clusters/$${local.cluster_name}?region=$${local.cluster_region}"
  }
}
EOT
}

resource "platform-orchestrator_module_rule" "cluster-creds" {
  for_each    = toset(var.runtime == "kubernetes" ? ["this"] : [])
  module_id   = platform-orchestrator_module.k8s-cluster-credentials["this"].id
  resource_id = module.k8s-common["this"].cluster_credentials_resource_id
}
