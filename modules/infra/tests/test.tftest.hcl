mock_provider "platform-orchestrator" {}

run "test_aws_kubernetes" {
  command = plan
  variables {
    inputs = {
      cloud            = "aws"
      runtime          = "kubernetes"
      primary_resource = "postgres"
    }
    runner_config = {
      region                     = "eu-central-1"
      subnet_ids                 = ["subnet1", "subnet2"]
      security_group_ids         = []
      humanitec_org_id           = "example"
      existing_ecs_cluster_name  = "ecs-cluster"
      oidc_hostname              = "oidc.humanitec.dev"
      existing_oidc_provider_arn = "arn"
    }
  }
}

run "test_gcp_kubernetes" {
  command = plan
  variables {
    inputs = {
      cloud            = "gcp"
      runtime          = "kubernetes"
      primary_resource = "postgres"
    }
    runner_config = {
      region                     = "eu-central-1"
      subnet_ids                 = ["subnet1", "subnet2"]
      security_group_ids         = []
      humanitec_org_id           = "example"
      existing_ecs_cluster_name  = "ecs-cluster"
      oidc_hostname              = "oidc.humanitec.dev"
      existing_oidc_provider_arn = "arn"
    }
  }
}

run "test_azure_kubernetes" {
  command = plan
  variables {
    inputs = {
      cloud            = "azure"
      runtime          = "kubernetes"
      primary_resource = "postgres"
    }
    runner_config = {
      region                     = "eu-central-1"
      subnet_ids                 = ["subnet1", "subnet2"]
      security_group_ids         = []
      humanitec_org_id           = "example"
      existing_ecs_cluster_name  = "ecs-cluster"
      oidc_hostname              = "oidc.humanitec.dev"
      existing_oidc_provider_arn = "arn"
    }
  }
}
