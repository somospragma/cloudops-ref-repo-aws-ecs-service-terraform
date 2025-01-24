###########################################
######### ECS Service Module ##############
###########################################

module "module_ecs_service_functionality" {
  source = "../../"

  providers = {
    aws.project = aws.alias01              #Write manually alias (the same alias name configured in providers.tf)
  }

  # Common configuration
  client      = var.client
  project     = var.project
  application = var.application
  aws_region  = var.aws_region
  environment = var.environment

  # ECS service configuration
  ecs_config = [
    {
      functionality            = var.functionality
      execution_role_arn       = "execution-role-arn"
      task_role_arn            = "execution-task-arn"
      network_mode             = "awsvpc"
      memory                   = var.memory
      cpu                      = var.cpu
      cpu_container            = var.cpu
      image                    = var.url_image_respository
      image_version            = "latest"
      requires_compatibilities = ["FARGATE"]
      cluster_name             = "cluster-name"

      environmentFiles = []

      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
          protocol      = "tcp"
        }
      ]

      environment_variables = []
      volumes               = []

      runtime_platform = {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
      }

      desired_count                     = 1
      health_check_grace_period_seconds = 60
      target_group_arn                  = "target-group"
      security_groups                   = ["xxxxxx"]
      subnets                           = ["xxxxxx", "xxxxxx"]
      assign_public_ip                  = "false"
      enable_rollback                   = "true"
      rollback                          = "true"

      secrets     = []
      parameters  = []
      entry_point = []
      command     = []
    }
  ]

  launch_type = "xxxxxxx"

  compute_configuration = "capacity_providers"
  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      base              = 0
      weight            = 1
    }
  ]
}