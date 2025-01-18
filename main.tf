resource "aws_ecs_task_definition" "task" {
  provider = aws.project
  # Definimos la tarea ECS
  for_each = { for item in var.ecs_config :
    item.application => {
      "index" : index(var.ecs_config, item)
      "execution_role_arn" : item.execution_role_arn
      "task_role_arn" : item.task_role_arn
      "network_mode" : item.network_mode
      "image_version" : item.image_version
      "memory" : item.memory
      "cpu" : item.cpu
      "cpu_container" : item.cpu_container
      "requires_compatibilities" : item.requires_compatibilities
      "portMappings" : item.portMappings
      "environmentFiles" : item.environmentFiles
      "environment_variables" : item.environment_variables
      "image" : item.image
      "runtime_platform" : item.runtime_platform
      "secrets" : item.secrets
      "parameters" : item.parameters
      "command" : item.command
      "entry_point" : item.entry_point
      "volumes" : item.volumes
    }
  }

  container_definitions = jsonencode(concat([
    {
      "name"      = join("-", [var.client, var.functionality, var.environment, "task", each.key, each.value["index"] + 1])
      "image"     = "${each.value["image"]}:${each.value["image_version"]}",
      "cpu"       = each.value["cpu_container"],
      "memory"    = each.value["memory"],
      "essential" = true,
      "linuxParameters" : {
        "initProcessEnabled" : true
      }
      "portMappings"     = each.value["portMappings"]
      "environmentFiles" = each.value["environmentFiles"]
      "environment" = [
        for env in each.value["environment_variables"] : {
          "name" : "${env.name}"
          "value" : "${env.value}"
        }
      ]
      "mountPoints" = [
        for mnt in each.value["volumes"] : {
          "sourceVolume" : "${mnt.volume_name}"
          "containerPath" : "${mnt.container_path}"
          "readOnly" : "${mnt.read_only}"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/${each.key}",
          "mode" : "non-blocking",
          "awslogs-create-group" : "true",
          "max-buffer-size" : "25m",
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        },
        "secretOptions" : []
      },

      "entryPoint" = length(lookup(each.value, "entry_point", [])) > 0 ? each.value["entry_point"] : ["/bin/sh", "-c"],

      "command" = length(lookup(each.value, "command", [])) > 0 ? each.value["command"] : [],



      "secrets" = flatten([
        for secret in each.value["secrets"] : {
          "name"      = secret.name,
          "valueFrom" = secret.arn
        }
      ]),

      "parameters" = flatten([
        for param in each.value["parameters"] : {
          "name"      = param.name,
          "valueFrom" = param.arn
        }
      ])

      "systemControls" : []
    }
  ]))

  execution_role_arn       = each.value["execution_role_arn"]
  family                   = join("-", tolist([var.client, var.functionality, var.environment, "task", each.key, each.value["index"] + 1]))
  network_mode             = each.value["network_mode"]
  memory                   = each.value["memory"]
  cpu                      = each.value["cpu"]
  task_role_arn            = each.value["task_role_arn"]
  requires_compatibilities = each.value["requires_compatibilities"]

  dynamic "volume" {
    for_each = each.value["volumes"]
    content {
      name = volume.value["volume_name"]
      efs_volume_configuration {
        file_system_id     = volume.value["file_system_id"]
        root_directory     = "/"
        transit_encryption = volume.value["transit_encryption"]
        authorization_config {
          access_point_id = volume.value["access_point_id"]
        }
      }
    }
  }

  runtime_platform {
    operating_system_family = each.value["runtime_platform"].operating_system_family
    cpu_architecture        = each.value["runtime_platform"].cpu_architecture
  }

  tags = merge(
    { Name = "${join("-", tolist([var.client, var.functionality, var.environment, "task", each.key, each.value["index"] + 1]))}" },
    { application_id = "${each.key}" },
    var.tags
  )
}

resource "aws_ecs_service" "ecs_service" {
  provider = aws.project
  for_each = { for item in var.ecs_config :
    item.application => {
      "index" : index(var.ecs_config, item)
      "desired_count" : item.desired_count,
      "health_check_grace_period_seconds" : item.health_check_grace_period_seconds,
      "target_group_arn" : item.target_group_arn,
      "container_port" : item.portMappings[0].containerPort,
      "security_groups" : item.security_groups,
      "subnets" : item.subnets,
      "assign_public_ip" : item.assign_public_ip,
      "enable_rollback" = item.enable_rollback
      "rollback"        = item.rollback
      "cluster_name" : item.cluster_name
    }
  }

  cluster       = data.aws_ecs_cluster.cluster[each.key].id
  desired_count = each.value["desired_count"]
  name          = join("-", tolist([var.client, var.functionality, var.environment, "service", each.key, each.value["index"] + 1]))
  #health_check_grace_period_seconds = each.value["health_check_grace_period_seconds"]
  task_definition        = aws_ecs_task_definition.task[each.key].arn
  enable_execute_command = true

  dynamic "capacity_provider_strategy" {
    for_each = var.compute_configuration == "capacity_providers" ? var.capacity_provider_strategy : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      base              = capacity_provider_strategy.value.base
      weight            = capacity_provider_strategy.value.weight
    }
  }

  launch_type = var.compute_configuration == "launch_type" ? var.launch_type : null

  dynamic "load_balancer" {
    for_each = each.value["target_group_arn"] != "" ? [1] : []
    content {
      container_name   = join("-", tolist([var.client, var.environment, each.key, "task"]))
      container_port   = each.value["container_port"]
      target_group_arn = each.value["target_group_arn"]
    }
  }

  # Condicional para el health_check_grace_period_seconds solo si hay un balanceador de carga
  health_check_grace_period_seconds = each.value["target_group_arn"] != "" ? each.value["health_check_grace_period_seconds"] : 0


  network_configuration {
    security_groups  = each.value["security_groups"]
    subnets          = each.value["subnets"]
    assign_public_ip = each.value["assign_public_ip"]
  }

  deployment_circuit_breaker {
    enable   = each.value["enable_rollback"]
    rollback = each.value["rollback"]
  }

  tags = merge(
    { Name = "${join("-", tolist([var.client, var.functionality, var.environment, "service", each.key, each.value["index"] + 1]))}" },
    { application_id = "${each.key}" },
    var.tags
  )
}




resource "aws_cloudwatch_log_group" "log" {
  provider = aws.project
  for_each = { for item in var.ecs_config :
    item.application => {
      "index" : index(var.ecs_config, item)
      "application" : item.application
    }
  }
  name              = "/ecs/${each.key}"
  retention_in_days = 0
  tags = merge({ Name = "${join("-", tolist([var.client, var.environment, each.key, "log"]))}" },
    { application_id = "${each.key}" },
  var.tags)
}


resource "aws_appautoscaling_target" "ecs_target" {
  provider = aws.project
  for_each = { for item in var.ecs_config :
    item.application => {
      "index" : index(var.ecs_config, item)
      "cluster_name" : item.cluster_name
      "max_capacity" : item.autoscaling.max_capacity
      "min_capacity" : item.autoscaling.min_capacity
    } if item.autoscaling != null
  }
  max_capacity       = each.value["max_capacity"]
  min_capacity       = each.value["min_capacity"]
  resource_id        = "service/${each.value["cluster_name"]}/${aws_ecs_service.ecs_service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = merge({ Name = "${join("-", tolist([var.client, var.environment, each.key, "tag"]))}" },
    { application_id = "${each.key}" },
  var.tags)
}


resource "aws_appautoscaling_policy" "ecs_policy" {
  provider = aws.project
  for_each = { for item in var.ecs_config :
    item.application => {
      "index" : index(var.ecs_config, item)
      "cluster_name" : item.cluster_name
      "target_value" : item.autoscaling.target_value
      "scale_in_cooldown" : item.autoscaling.scale_in_cooldown
      "scale_out_cooldown" : item.autoscaling.scale_out_cooldown
    } if item.autoscaling != null
  }
  name               = join("-", tolist([var.client, var.environment, each.key, "policy"]))
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = each.value["target_value"]
    scale_in_cooldown  = each.value["scale_in_cooldown"]
    scale_out_cooldown = each.value["scale_out_cooldown"]
  }
}
