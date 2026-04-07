variable "client" {
  description = "Nombre del cliente asociado a los servicios ECS"
  type        = string
  default     = "creci"
}

variable "project" {
  description = "Nombre del proyecto asociado a los servicios ECS"
  type        = string
  default     = "mapa-crecimiento"
}

variable "environment" {
  description = "Entorno en el que se desplegarán los servicios ECS (dev, qa, pdn)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}

variable "ecs_services" {
  description = "Configuración de servicios ECS"
  type = map(object({
    # Configuración del servicio
    cluster_name               = string
    desired_count              = number
    deployment_maximum_percent = optional(number, 200)
    deployment_minimum_percent = optional(number, 100)
    enable_execute_command     = optional(bool, false)
    force_new_deployment       = optional(bool, false)
    health_check_grace_period  = optional(number, 0)
    launch_type                = optional(string, "FARGATE")
    platform_version           = optional(string, "LATEST")
    scheduling_strategy        = optional(string, "REPLICA")
    pid_mode                   = optional(string, null)

    # Configuración de red
    assign_public_ip = optional(bool, false)
    subnets          = list(string)
    security_groups  = list(string)

    # Configuración de definición de tarea
    task_cpu                 = number
    task_memory              = number
    requires_compatibilities = optional(list(string), ["FARGATE"])
    execution_role_arn       = string
    task_role_arn            = string

    # Configuración de contenedores
    containers = map(object({
      image                    = string
      cpu                      = optional(number, null)
      memory                   = optional(number, null)
      memory_reservation       = optional(number, null)
      essential                = optional(bool, true)
      readonly_root_filesystem = optional(bool, false)
      user                     = optional(string, null)
      docker_labels            = optional(map(string), {})
      
      linux_parameters         = optional(object({
        capabilities = optional(object({
          add  = optional(list(string), [])
          drop = optional(list(string), [])
        }), null)
        init_process_enabled = optional(bool, false)
      }), null)

      port_mappings = optional(list(object({
        name           = optional(string, null)
        container_port = number
        host_port      = optional(number, null)
        protocol       = optional(string, "tcp")
      })), [])

      environment = optional(list(object({
        name  = string
        value = string
      })), [])

      secrets = optional(list(object({
        name       = string
        value_from = string
      })), [])

      enable_cloudwatch_logs = optional(bool, true)
      log_configuration = optional(object({
        log_driver = optional(string, "awslogs")
        options    = optional(map(string), {})
        secret_options = optional(list(object({
          name       = string
          value_from = string
        })), [])
      }), null)
      
      firelens_configuration = optional(object({
        type    = string
        options = optional(map(string), {})
      }), null)

      healthcheck = optional(object({
        command      = list(string)
        interval     = optional(number, 30)
        timeout      = optional(number, 5)
        retries      = optional(number, 3)
        start_period = optional(number, 0)
      }), null)

      mount_points = optional(list(object({
        container_path = string
        source_volume  = string
        read_only      = optional(bool, false)
      })), [])

      depends_on = optional(list(object({
        container_name = string
        condition      = string
      })), [])
    }))

    volumes = optional(list(object({
      name = string
      efs_volume_configuration = optional(object({
        file_system_id          = string
        root_directory          = optional(string, "/")
        transit_encryption      = optional(string, "ENABLED")
        transit_encryption_port = optional(number, null)
        authorization_config = optional(object({
          access_point_id = string
          iam             = optional(string, "ENABLED")
        }), null)
      }), null)
      host_path = optional(string, null)
      docker_volume_configuration = optional(object({
        scope         = optional(string, "shared")
        autoprovision = optional(bool, true)
        driver        = optional(string, "local")
        driver_opts   = optional(map(string), {})
        labels        = optional(map(string), {})
      }), null)
    })), [])

    load_balancer = optional(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    }), null)

    service_connect_config = optional(object({
      enabled   = optional(bool, false)
      namespace = optional(string, null)
      service = optional(object({
        port_name      = string
        discovery_name = optional(string, null)
        client_alias = optional(list(object({
          port     = number
          dns_name = string
        })), [])
      }), null)
      log_configuration = optional(object({
        log_driver = optional(string, "awslogs")
        options    = optional(map(string), {})
      }), null)
    }), null)

    enable_autoscaling = optional(bool, false)
    autoscaling_config = optional(object({
      min_capacity = optional(number, 1)
      max_capacity = optional(number, 10)
      scaling_policies = optional(list(object({
        name        = string
        policy_type = optional(string, "TargetTrackingScaling")
        target_tracking_configuration = optional(object({
          target_value           = number
          scale_in_cooldown      = optional(number, 300)
          scale_out_cooldown     = optional(number, 300)
          predefined_metric_type = string
          disable_scale_in       = optional(bool, false)
        }), null)
        step_scaling_configuration = optional(object({
          adjustment_type         = optional(string, "ChangeInCapacity")
          cooldown                = optional(number, 300)
          metric_aggregation_type = optional(string, "Average")
          step_adjustments = list(object({
            scaling_adjustment          = number
            metric_interval_lower_bound = optional(number, null)
            metric_interval_upper_bound = optional(number, null)
          }))
        }), null)
      })), [])
      alarms = optional(list(object({
        name                = string
        comparison_operator = string
        evaluation_periods  = number
        metric_name         = string
        namespace           = string
        period              = number
        statistic           = string
        threshold           = number
        alarm_description   = optional(string, "")
        datapoints_to_alarm = optional(number, null)
        treat_missing_data  = optional(string, "missing")
        dimensions          = optional(map(string), {})
      })), [])
    }), null)

    log_retention_days     = optional(number, 30)
    log_encryption_key_arn = optional(string, null)
    additional_tags = optional(map(string), {})
  }))
  default = {}
}
