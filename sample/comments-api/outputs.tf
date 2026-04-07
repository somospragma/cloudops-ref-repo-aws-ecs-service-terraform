output "ecs_service_arns" {
  description = "ARNs de los servicios ECS creados"
  value = {
    for k, v in module.ecs_services.ecs_service_arns : k => v
  }
}

output "ecs_task_definition_arns" {
  description = "ARNs de las definiciones de tareas ECS creadas"
  value = {
    for k, v in module.ecs_services.ecs_task_definition_arns : k => v
  }
}

output "cloudwatch_log_groups" {
  description = "Nombres de los grupos de logs de CloudWatch creados"
  value = {
    for k, v in module.ecs_services.cloudwatch_log_groups : k => v
  }
}

output "autoscaling_target_arns" {
  description = "ARNs de los targets de auto-scaling creados"
  value = {
    for k, v in module.ecs_services.autoscaling_target_arns : k => v
  }
}
