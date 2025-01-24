###########################################
########### Data - Cluster name ###########
###########################################

data "aws_ecs_cluster" "cluster" {
  provider = aws.project
  for_each = { for item in var.ecs_config :
    item.functionality => {
      "cluster_name" : item.cluster_name
    }
  }
  cluster_name = each.value["cluster_name"]
}


data "aws_region" "current" {
  provider = aws.project
}

###########################################
########### Data - Account ID #############
###########################################

data "aws_caller_identity" "current" {
  provider = aws.project
}