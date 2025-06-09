######################################################################
# Módulo ECS Services
######################################################################
module "ecs_services" {
  source = "./module/ecs-service"
  
  providers = {
    aws.project = aws.principal
  }
  
  client      = var.client
  project     = var.project
  environment = var.environment
  
  ecs_services = var.ecs_services
}

