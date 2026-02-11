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
    pid_mode                   = optional(string, null)  # Agregar soporte para pid_mode

    # Configuración de Capacity Providers
    use_capacity_providers = optional(bool, false) # Si es true, se usarán capacity providers en lugar de launch_type
    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      base              = optional(number, 0)
      weight            = optional(number, 1)
    })), [])

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

    # Configuración de runtime platform para soporte ARM64/x86_64
    runtime_platform = optional(object({
      operating_system_family = optional(string, "LINUX")
      cpu_architecture        = optional(string, "X86_64") # X86_64 o ARM64
    }), null)

    # Configuración de contenedores
    containers = map(object({
      image                    = string
      cpu                      = optional(number, null)
      memory                   = optional(number, null)
      memory_reservation       = optional(number, null)
      essential                = optional(bool, true)
      readonly_root_filesystem = optional(bool, false)
      
      # Nuevos campos para Datadog CWS
      entry_point              = optional(list(string), null)
      command                  = optional(list(string), null)
      user                     = optional(string, null)
      
      # Etiquetas Docker
      docker_labels            = optional(map(string), {})
      
      # Configuración de Linux Parameters
      linux_parameters         = optional(object({
        capabilities = optional(object({
          add  = optional(list(string), [])
          drop = optional(list(string), [])
        }), null)
        init_process_enabled = optional(bool, false)
      }), null)

      # Configuración de puertos
      port_mappings = optional(list(object({
        name           = optional(string, null) # Nombre para Service Connect
        container_port = number
        host_port      = optional(number, null)
        protocol       = optional(string, "tcp")
      })), [])

      # Configuración de entorno
      environment = optional(list(object({
        name  = string
        value = string
      })), [])

      # Configuración de secretos
      secrets = optional(list(object({
        name       = string
        value_from = string
      })), [])

      # Configuración de logs
      enable_cloudwatch_logs = optional(bool, true)
      log_configuration = optional(object({
        log_driver = optional(string, "awslogs")
        options    = optional(map(string), {})
        secret_options = optional(list(object({
          name       = string
          value_from = string
        })), [])
      }), null)
      
      # Configuración de FireLens
      firelens_configuration = optional(object({
        type    = string
        options = optional(map(string), {})
      }), null)

      # Configuración de healthcheck
      healthcheck = optional(object({
        command      = list(string)
        interval     = optional(number, 30)
        timeout      = optional(number, 5)
        retries      = optional(number, 3)
        start_period = optional(number, 0)
      }), null)

      # Configuración de montaje de volúmenes
      mount_points = optional(list(object({
        container_path = string
        source_volume  = string
        read_only      = optional(bool, false)
      })), [])

      # Configuración de dependencias
      depends_on = optional(list(object({
        container_name = string
        condition      = string
      })), [])
    }))

    # Configuración de volúmenes
    volumes = optional(list(object({
      name = string

      # Configuración de EFS
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

      # Configuración de host
      host_path = optional(string, null)

      # Configuración de Docker
      docker_volume_configuration = optional(object({
        scope         = optional(string, "shared")
        autoprovision = optional(bool, true)
        driver        = optional(string, "local")
        driver_opts   = optional(map(string), {})
        labels        = optional(map(string), {})
      }), null)
    })), [])

    # Configuración de balanceador de carga
    # Permite especificar qué contenedor y puerto se expondrá a través del balanceador de carga
    load_balancer = optional(object({
      target_group_arn = string
      container_name   = string # Debe coincidir con una de las claves en el mapa 'containers'
      container_port   = number
    }), null)

    # Configuración de Service Connect
    service_connect_config = optional(object({
      enabled   = optional(bool, false)
      namespace = optional(string, null) # ARN o nombre del namespace de Service Connect (opcional)
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

    # Configuración de Auto Scaling
    enable_autoscaling = optional(bool, false)
    autoscaling_config = optional(object({
      min_capacity = optional(number, 1)
      max_capacity = optional(number, 10)

      # Políticas de escalado
      scaling_policies = optional(list(object({
        name        = string
        policy_type = optional(string, "TargetTrackingScaling")

        # Configuración de Target Tracking
        target_tracking_configuration = optional(object({
          target_value           = number
          scale_in_cooldown      = optional(number, 300)
          scale_out_cooldown     = optional(number, 300)
          predefined_metric_type = string
          disable_scale_in       = optional(bool, false)
        }), null)

        # Configuración de Step Scaling
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

      # Configuración de alarmas de CloudWatch
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

    # Configuración de logs
    log_retention_days     = optional(number, 30)
    log_encryption_key_arn = optional(string, null) # ARN de la clave KMS para encriptar logs

    # Etiquetas adicionales específicas para este servicio
    additional_tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      length(v.subnets) > 0
    ])
    error_message = "Debe proporcionar al menos una subred para el servicio ECS."
  }

  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      length(v.security_groups) > 0
    ])
    error_message = "Debe proporcionar al menos un grupo de seguridad para el servicio ECS."
  }

  # Validación para asegurar que al menos un contenedor sea esencial en cada servicio
  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      anytrue([
        for ck, cv in v.containers :
        cv.essential == true
      ])
    ])
    error_message = "Al menos un contenedor debe ser marcado como esencial (essential = true) en cada servicio ECS."
  }


  # Validación para asegurar que el contenedor referenciado en el balanceador de carga existe
  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      v.load_balancer == null ? true : contains(keys(v.containers), v.load_balancer.container_name)
    ])
    error_message = "El contenedor especificado en load_balancer.container_name debe existir en el mapa de contenedores."
  }

  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      v.log_encryption_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", v.log_encryption_key_arn))
    ])
    error_message = "El ARN de la clave KMS debe tener un formato válido (arn:aws:kms:region:account-id:key/key-id)."
  }

  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      contains(["FARGATE", "EC2"], v.launch_type)
    ])
    error_message = "El tipo de lanzamiento debe ser 'FARGATE' o 'EC2'."
  }

  validation {
    condition = alltrue([
      for k, v in var.ecs_services :
      contains(["REPLICA", "DAEMON"], v.scheduling_strategy)
    ])
    error_message = "La estrategia de programación debe ser 'REPLICA' o 'DAEMON'."
  }
  default = {}
}

variable "project" {
  description = "Nombre del proyecto asociado a los servicios ECS"
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "El valor de project no puede estar vacío."
  }
}

variable "client" {
  description = "Nombre del cliente asociado a los servicios ECS"
  type        = string

  validation {
    condition     = length(var.client) > 0
    error_message = "El valor de client no puede estar vacío."
  }
}

variable "environment" {
  description = "Entorno en el que se desplegarán los servicios ECS (dev, qa, pdn)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}