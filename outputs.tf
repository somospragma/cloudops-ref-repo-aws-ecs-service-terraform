output "ecs_services" {
  description = "Información de los servicios ECS creados"
  value = {
    for k, v in aws_ecs_service.this : k => {
      id                  = v.id
      name                = v.name
      cluster             = v.cluster
      desired_count       = v.desired_count
      launch_type         = v.launch_type
      platform_version    = v.platform_version
      scheduling_strategy = v.scheduling_strategy
    }
  }
}

output "task_definitions" {
  description = "Información de las definiciones de tareas ECS creadas"
  value = {
    for k, v in aws_ecs_task_definition.this : k => {
      id                = v.id
      arn               = v.arn
      family            = v.family
      revision          = v.revision
      cpu               = v.cpu
      memory            = v.memory
      execution_role_arn = v.execution_role_arn
      task_role_arn     = v.task_role_arn
    }
  }
}

output "cloudwatch_log_groups" {
  description = "Información de los grupos de logs de CloudWatch creados"
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => {
      name              = v.name
      arn               = v.arn
      retention_in_days = v.retention_in_days
    }
  }
}

output "container_log_groups" {
  description = "Información de los grupos de logs de CloudWatch para contenedores"
  value = {
    for k, v in aws_cloudwatch_log_group.container : k => {
      name              = v.name
      arn               = v.arn
      retention_in_days = v.retention_in_days
    }
  }
}

output "autoscaling_targets" {
  description = "Información de los objetivos de Auto Scaling"
  value = {
    for k, v in aws_appautoscaling_target.this : k => {
      resource_id        = v.resource_id
      scalable_dimension = v.scalable_dimension
      service_namespace  = v.service_namespace
      min_capacity       = v.min_capacity
      max_capacity       = v.max_capacity
    }
  }
}

output "autoscaling_policies" {
  description = "Información de las políticas de Auto Scaling"
  value = {
    for k, v in aws_appautoscaling_policy.this : k => {
      name               = v.name
      policy_type        = v.policy_type
      resource_id        = v.resource_id
      scalable_dimension = v.scalable_dimension
      service_namespace  = v.service_namespace
    }
  }
}

output "cloudwatch_alarms" {
  description = "Información de las alarmas de CloudWatch para Auto Scaling"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.autoscaling : k => {
      alarm_name          = v.alarm_name
      comparison_operator = v.comparison_operator
      evaluation_periods  = v.evaluation_periods
      metric_name         = v.metric_name
      namespace           = v.namespace
      period              = v.period
      statistic           = v.statistic
      threshold           = v.threshold
    }
  }
}


output "load_balancer_config" {
  description = "Configuración del balanceador de carga para depuración"
  value = {
    for k, v in var.ecs_services : k => {
      load_balancer = v.load_balancer
      health_check_grace_period = v.health_check_grace_period
    }
  }
}