# Definición de tarea ECS
resource "aws_ecs_task_definition" "this" {
  provider = aws.project
  for_each = var.ecs_services
  
  family                   = local.task_definition_names[each.key]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = each.value.requires_compatibilities
  execution_role_arn       = each.value.execution_role_arn
  task_role_arn            = each.value.task_role_arn
  pid_mode                 = each.value.pid_mode  # Agregar soporte para pid_mode
  
  # Configuración de contenedores
  container_definitions = jsonencode([
    for container_key, container in each.value.containers : {
      name                   = container_key
      image                  = container.image
      cpu                    = container.cpu
      memory                 = container.memory
      memoryReservation      = container.memory_reservation
      essential              = container.essential
      readonlyRootFilesystem = container.readonly_root_filesystem
      user                   = container.user
      
      # Etiquetas Docker
      dockerLabels           = container.docker_labels != null ? container.docker_labels : {}
      
      # Linux Parameters para capacidades
      linuxParameters = container.linux_parameters != null ? {
        capabilities = container.linux_parameters.capabilities != null ? {
          add  = container.linux_parameters.capabilities.add
          drop = container.linux_parameters.capabilities.drop
        } : null
        initProcessEnabled = container.linux_parameters.init_process_enabled
      } : null
      
      portMappings = [
        for port in container.port_mappings : {
          name          = port.name
          containerPort = port.container_port
          hostPort      = port.host_port != null ? port.host_port : port.container_port
          protocol      = port.protocol
        }
      ]
      
      environment = [
        for env in container.environment : {
          name  = env.name
          value = env.value
        }
      ]
      
      secrets = [
        for secret in container.secrets : {
          name      = secret.name
          valueFrom = secret.value_from
        }
      ]
      
      logConfiguration = container.log_configuration != null ? {
        logDriver = container.log_configuration.log_driver
        options   = container.log_configuration.options
        secretOptions = container.log_configuration.secret_options != null ? [
          for secret in container.log_configuration.secret_options : {
            name      = secret.name
            valueFrom = secret.value_from
          }
        ] : []
      } : (container.enable_cloudwatch_logs != false ? {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = "/aws/ecs/${local.service_names[each.key]}/${container_key}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = container_key
          "awslogs-create-group"  = "true"
        }
        secretOptions = []
      } : null)
      
      # Configuración de FireLens
      firelensConfiguration = container.firelens_configuration != null ? {
        type    = container.firelens_configuration.type
        options = container.firelens_configuration.options
      } : null
      
      healthCheck = container.healthcheck != null ? {
        command     = container.healthcheck.command
        interval    = container.healthcheck.interval
        timeout     = container.healthcheck.timeout
        retries     = container.healthcheck.retries
        startPeriod = container.healthcheck.start_period
      } : null
      
      mountPoints = [
        for mount in container.mount_points : {
          containerPath = mount.container_path
          sourceVolume  = mount.source_volume
          readOnly      = mount.read_only
        }
      ]
      
      dependsOn = [
        for dep in container.depends_on : {
          containerName = dep.container_name
          condition     = dep.condition
        }
      ]
    }
  ])
  
  # Configuración de volúmenes
  dynamic "volume" {
    for_each = each.value.volumes != null ? each.value.volumes : []
    
    content {
      name = volume.value.name
      
      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port
          
          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [efs_volume_configuration.value.authorization_config] : []
            
            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }
      
      host_path = volume.value.host_path
      
      dynamic "docker_volume_configuration" {
        for_each = volume.value.docker_volume_configuration != null ? [volume.value.docker_volume_configuration] : []
        
        content {
          scope         = docker_volume_configuration.value.scope
          autoprovision = docker_volume_configuration.value.autoprovision
          driver        = docker_volume_configuration.value.driver
          driver_opts   = docker_volume_configuration.value.driver_opts
          labels        = docker_volume_configuration.value.labels
        }
      }
    }
  }
  
  # Etiquetas
  tags = merge(
    {
      Name = local.task_definition_names[each.key]
    },
    each.value.additional_tags
  )
}

# Servicio ECS
resource "aws_ecs_service" "this" {
  provider = aws.project
  for_each = var.ecs_services
  
  name                               = local.service_names[each.key]
  cluster                            = data.aws_ecs_cluster.this[each.key].id
  task_definition                    = aws_ecs_task_definition.this[each.key].arn
  desired_count                      = each.value.desired_count
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_percent
  enable_execute_command             = each.value.enable_execute_command
  force_new_deployment               = each.value.force_new_deployment
  health_check_grace_period_seconds  = each.value.load_balancer != null ? each.value.health_check_grace_period : null
  launch_type                        = each.value.launch_type
  platform_version                   = each.value.platform_version
  scheduling_strategy                = each.value.scheduling_strategy
  
  # Configuración de red
  network_configuration {
    subnets          = each.value.subnets
    security_groups  = each.value.security_groups
    assign_public_ip = each.value.assign_public_ip
  }
  
  # Configuración de balanceador de carga
  dynamic "load_balancer" {
    for_each = each.value.load_balancer != null ? [each.value.load_balancer] : []
    
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }
  
  # Configuración de Service Connect
  dynamic "service_connect_configuration" {
    for_each = each.value.service_connect_config != null ? (each.value.service_connect_config.enabled ? [each.value.service_connect_config] : []) : []
    
    content {
      enabled = true
      namespace = service_connect_configuration.value.namespace
      
      dynamic "service" {
        for_each = service_connect_configuration.value.service != null ? [service_connect_configuration.value.service] : []
        
        content {
          port_name = service.value.port_name
          discovery_name = service.value.discovery_name
          
          dynamic "client_alias" {
            for_each = service.value.client_alias
            
            content {
              port = client_alias.value.port
              dns_name = client_alias.value.dns_name
            }
          }
        }
      }
      
      dynamic "log_configuration" {
        for_each = service_connect_configuration.value.log_configuration != null ? [service_connect_configuration.value.log_configuration] : []
        
        content {
          log_driver = log_configuration.value.log_driver
          options = log_configuration.value.options
        }
      }
    }
  }
  
  # Etiquetas
  tags = merge(
    {
      Name = local.service_names[each.key]
    },
    each.value.additional_tags
  )
  
  # Dependencias
  depends_on = [aws_cloudwatch_log_group.this]
}

# Grupos de logs de CloudWatch
resource "aws_cloudwatch_log_group" "this" {
  provider = aws.project
  for_each = var.ecs_services
  
  name              = local.log_group_names[each.key]
  retention_in_days = each.value.log_retention_days
  kms_key_id        = each.value.log_encryption_key_arn  # Si es null, AWS usa su clave predeterminada
  
  # Etiquetas
  tags = merge(
    {
      Name = local.log_group_names[each.key]
    },
    each.value.additional_tags
  )
}

# Grupos de logs para contenedores individuales
resource "aws_cloudwatch_log_group" "container" {
  provider = aws.project
  for_each = {
    for item in flatten([
      for service_key, service in var.ecs_services : [
        for container_key, container in service.containers : {
          service_key   = service_key
          container_key = container_key
          service       = service
          container     = container
          unique_key    = "${service_key}-${container_key}"
        }
        if container.enable_cloudwatch_logs != false
      ]
    ]) : item.unique_key => item
  }
  
  name              = "/aws/ecs/${local.service_names[each.value.service_key]}/${each.value.container_key}"
  retention_in_days = each.value.service.log_retention_days
  kms_key_id        = each.value.service.log_encryption_key_arn  # Si es null, AWS usa su clave predeterminada
  
  # Etiquetas
  tags = merge(
    {
      Name = "/aws/ecs/${local.service_names[each.value.service_key]}/${each.value.container_key}"
    },
    each.value.service.additional_tags
  )
}

# Auto Scaling para servicios ECS
resource "aws_appautoscaling_target" "this" {
  provider = aws.project
  for_each = {
    for k, v in var.ecs_services : k => v
    if v.enable_autoscaling
  }
  
  max_capacity       = each.value.autoscaling_config.max_capacity
  min_capacity       = each.value.autoscaling_config.min_capacity
  resource_id        = "service/${data.aws_ecs_cluster.this[each.key].cluster_name}/${aws_ecs_service.this[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Políticas de Auto Scaling
resource "aws_appautoscaling_policy" "this" {
  provider = aws.project
  for_each = {
    for item in flatten([
      for service_key, service in var.ecs_services : [
        for policy in service.autoscaling_config != null ? service.autoscaling_config.scaling_policies : [] : {
          service_key = service_key
          policy      = policy
          unique_key  = "${service_key}-${policy.name}"
        }
      ]
      if service.enable_autoscaling
    ]) : item.unique_key => item
  }
  
  name               = each.value.policy.name
  policy_type        = each.value.policy.policy_type
  resource_id        = aws_appautoscaling_target.this[each.value.service_key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.value.service_key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.value.service_key].service_namespace
  
  # Configuración de Target Tracking
  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = each.value.policy.policy_type == "TargetTrackingScaling" && each.value.policy.target_tracking_configuration != null ? [each.value.policy.target_tracking_configuration] : []
    
    content {
      target_value       = target_tracking_scaling_policy_configuration.value.target_value
      scale_in_cooldown  = target_tracking_scaling_policy_configuration.value.scale_in_cooldown
      scale_out_cooldown = target_tracking_scaling_policy_configuration.value.scale_out_cooldown
      disable_scale_in   = target_tracking_scaling_policy_configuration.value.disable_scale_in
      
      predefined_metric_specification {
        predefined_metric_type = target_tracking_scaling_policy_configuration.value.predefined_metric_type
      }
    }
  }
  
  # Configuración de Step Scaling
  dynamic "step_scaling_policy_configuration" {
    for_each = each.value.policy.policy_type == "StepScaling" && each.value.policy.step_scaling_configuration != null ? [each.value.policy.step_scaling_configuration] : []
    
    content {
      adjustment_type         = step_scaling_policy_configuration.value.adjustment_type
      cooldown                = step_scaling_policy_configuration.value.cooldown
      metric_aggregation_type = step_scaling_policy_configuration.value.metric_aggregation_type
      
      dynamic "step_adjustment" {
        for_each = step_scaling_policy_configuration.value.step_adjustments
        
        content {
          scaling_adjustment          = step_adjustment.value.scaling_adjustment
          metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
          metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
        }
      }
    }
  }
}

# Alarmas de CloudWatch para Auto Scaling
resource "aws_cloudwatch_metric_alarm" "autoscaling" {
  provider = aws.project
  for_each = {
    for item in flatten([
      for service_key, service in var.ecs_services : [
        for alarm in service.autoscaling_config != null ? service.autoscaling_config.alarms : [] : {
          service_key = service_key
          alarm       = alarm
          unique_key  = "${service_key}-${alarm.name}"
        }
      ]
      if service.enable_autoscaling
    ]) : item.unique_key => item
  }
  
  alarm_name          = "${var.client}-${var.project}-${var.environment}-${each.value.alarm.name}"
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods  = each.value.alarm.evaluation_periods
  metric_name         = each.value.alarm.metric_name
  namespace           = each.value.alarm.namespace
  period              = each.value.alarm.period
  statistic           = each.value.alarm.statistic
  threshold           = each.value.alarm.threshold
  alarm_description   = each.value.alarm.alarm_description
  datapoints_to_alarm = each.value.alarm.datapoints_to_alarm
  treat_missing_data  = each.value.alarm.treat_missing_data
  dimensions          = each.value.alarm.dimensions
  
  # Etiquetas
  tags = merge(
    {
      Name = "${var.client}-${var.project}-${var.environment}-${each.value.alarm.name}"
    },
    var.ecs_services[each.value.service_key].additional_tags
  )
}
