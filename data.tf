data "aws_ecs_cluster" "cluster" {
  for_each = { for item in var.ecs_config :
    item.application => {
      "cluster_name" : item.cluster_name
    }
  }
  cluster_name = each.value["cluster_name"]
}


data "aws_region" "current" {}



########################################################################
#Data Account ID
########################################################################
data "aws_caller_identity" "current" {}