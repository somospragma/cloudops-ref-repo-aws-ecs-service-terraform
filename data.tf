data "aws_caller_identity" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}

# Obtener información del cluster ECS
data "aws_ecs_cluster" "this" {
  provider = aws.project
  for_each = var.ecs_services
  
  cluster_name = each.value.cluster_name
}
