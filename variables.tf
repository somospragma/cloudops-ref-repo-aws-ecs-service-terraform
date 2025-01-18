variable "ecs_config" {
  type = list(object({
    execution_role_arn       = string
    task_role_arn            = string
    network_mode             = string
    memory                   = number
    cpu                      = number
    cpu_container            = number
    #datadog = bool
    requires_compatibilities = list(string)
    image_version            = string
    portMappings = list(object({
      containerPort = number
      hostPort      = number
    }))
    environmentFiles = list(object({
      value = string
      type  = string
    }))
    environment_variables = list(object({
      name  = string
      value = string
    }))
    application = string
    image       = string
    volumes = list(object({
      read_only          = bool
      volume_name        = string
      file_system_id     = string
      container_path     = string
      transit_encryption = string
      access_point_id    = string
    }))

    runtime_platform = object({
      operating_system_family = string
      cpu_architecture        = string
    })

    # Secrets y Parameters simples
    secrets = list(object({
      name      = string
      arn       = string
    }))
    parameters = list(object({
      name      = string
      arn       = string
    }))

    //ECS service variables
    desired_count                     = number
    #launch_type                       = string
    health_check_grace_period_seconds = number
    target_group_arn                  = string
    security_groups                   = list(string)
    subnets                           = list(string)
    assign_public_ip                  = string
    enable_rollback                   = string
    rollback                          = string
    //cluster if is external cluster
    cluster_name = string

    # Nuevas variables para entryPoint y command
    entry_point = optional(list(string))  # entryPoint opcional
    command     = optional(list(string))  # command opcional

    //Autoscaling 
    autoscaling = optional(object({
      max_capacity = number
      min_capacity = number
      target_value = number
      scale_in_cooldown = number
      scale_out_cooldown = number
    }))

  }))
}

# variable "service" {
#   type = string
# }

variable "client" {
  type = string
}

variable "environment" {
  type = string
}

# variable "project" {
#     description = "Nombre Del Proyecto"
#     type = string
# }

variable "functionality" {
    description = "Nombre Del Proyecto"
    type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

######################################################################
# Variable SecretDatadog
######################################################################
# variable "datadog_secrets" {
#   type = object({
#     secret_name = string
#     variables = list(object({
#       key          = string
#       env_var_name = string
#     }))
#   })
#   default = null
# }

# variable "datadog_api_key_secret" {
#   type        = string
#   description = "ARN of the AWS Secrets Manager secret for Datadog API key"
# }



# variable para definir si usar launch_type o capacity providers
variable "compute_configuration" {
  description = "Define si se debe usar launch_type (FARGATE) o capacity providers (FARGATE, FARGATE_SPOT)"
  type = string
  default = "launch_type"  # Los valores posibles serán "launch_type" o "capacity_providers"
}

# Si compute_configuration es 'capacity_providers', este bloque define los providers
variable "capacity_provider_strategy" {
  description = "Estrategia para usar FARGATE o FARGATE_SPOT como capacity providers"
  type = list(object({
    capacity_provider = string
    base              = number
    weight            = number
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      base              = 1
      weight            = 1
    }
  ]  # Valor por defecto para usar FARGATE
}

# Variable para launch type si se decide usarlo
variable "launch_type" {
  description = "Launch type para el servicio ECS (solo se usa si se selecciona `launch_type` en compute_configuration)"
  type = string
  default = "FARGATE"
}