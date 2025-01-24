###########################################
########## Common variables ###############
###########################################

variable "environment" {
  type = string
  description = "Environment where resources will be deployed"
}

variable "aws_region" {
  type = string
  description = "AWS region where resources will be deployed"
}

variable "client" {
  type = string
  description = "Client name"
}

variable "project" {
  type = string  
    description = "Project name"
}

variable "application" {
  type = string  
  description = "Application name"
}

###########################################
######## ECS Cluster variables ############
###########################################

variable "ecs_config" {
  type = list(object({
    execution_role_arn       = string
    task_role_arn            = string
    network_mode             = string
    image_version            = string
    memory                   = number
    cpu                      = number
    cpu_container            = number
    requires_compatibilities = list(string)

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

    functionality = string
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

    secrets = list(object({
      name      = string
      arn       = string
    }))

    parameters = list(object({
      name      = string
      arn       = string
    }))

    desired_count                     = number
    health_check_grace_period_seconds = number
    target_group_arn                  = string
    security_groups                   = list(string)
    subnets                           = list(string)
    assign_public_ip                  = string
    enable_rollback                   = string
    rollback                          = string
    cluster_name                      = string
    entry_point                       = optional(list(string))
    command                           = optional(list(string))

    autoscaling = optional(object({
      max_capacity = number
      min_capacity = number
      target_value = number
      scale_in_cooldown = number
      scale_out_cooldown = number
    }))
  }))
  description = <<EOF
    - execution_role_arn: (string) ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
    - task_role_arn: (string) ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services.
    - network_mode: (string) Docker networking mode to use for the containers in the task. Valid values are none, bridge, awsvpc, and host.
    - image_version: (string) Version of ECR image.
    - memory - (number) Amount (in MiB) of memory used by the task. If the requires_compatibilities is FARGATE this field is required.
    - cpu: (number) Number of cpu units used by the task. If the requires_compatibilities is FARGATE this field is required.
    - cpu_container (number) The number of cpu units reserved for the container.
    - requires_compatibilities: (list(string)) Set of launch types required by the task. The valid values are EC2 and FARGATE.

    - portMappings: (list(object))
      - containerPort: (number) Port on the container to associate with the load balancer.
      - hostPort: (number) For task definitions that use the awsvpc network mode, only specify the containerPort. The hostPort can be left blank or it must be the same value as the containerPort.

    - environmentFiles: (list(object))
      - value: (string) Environment value
      - type: (string) Environment type

    - environment_variables: (list(object())
      - name : (string) Environment name
      - value: (string) Environment value

    - functionality: (string) Functionality name.
    - image: (string) URL of ECR image.

    - volumes: list(object({
      - read_only: (bool) If this value is true, the container has read-only access to the volume. If this value is false, then the container can write to the volume. The default value is false.
      - volume_name: (string) The name of the volume to mount. Must be a volume name referenced in the name parameter of task definition volume.
      - container_path: (string) The path on the container to mount the host volume at.
      - file_system_id: (string) ID of the EFS File System.
      - transit_encryption: (string) Whether or not to enable encryption for Amazon EFS data in transit between the Amazon ECS host and the Amazon EFS server. Transit encryption must be enabled if Amazon EFS IAM authorization is used. Valid values: ENABLED, DISABLED. If this parameter is omitted, the default value of DISABLED is used.
      - access_point_id: (string) Access point ID to use. If an access point is specified, the root directory value will be relative to the directory set for the access point. If specified, transit encryption must be enabled in the EFSVolumeConfiguration.
    }))

    - runtime_platform: object({
      - operating_system_family: (string)  If the requires_compatibilities is FARGATE this field is required; must be set to a valid option from the operating system family in the runtime platform setting
      - cpu_architecture: (string) Must be set to either X86_64 or ARM64.
    })

    - secrets: (list(object))
      - name: (string) Secret name
      - arn: (string) The secret to expose to the container. The supported values are either the full ARN of the AWS Secrets Manager secret or the full ARN of the parameter in the SSM Parameter Store.

    - parameters: (list(object))
      - name: (string) Parameter name
      - arn: (string) PENDING

    - desired_count: (number) Number of instances of the task definition to place and keep running. Defaults to 0. Do not specify if using the DAEMON scheduling strategy. 
    - health_check_grace_period_seconds: (number) Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers.
    - target_group_arn: (string) ARN of the Load Balancer target group to associate with the service.
    - security_groups: (list(string)) Security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used.
    - subnets: list((string)) Subnets associated with the task or service.
    - assign_public_ip: (string) Assign a public IP address to the ENI (Fargate launch type only). Valid values are true or false. Default false.
    - enable_rollback: (string) Whether to enable the deployment circuit breaker logic for the service.
    - rollback: (string) Whether to enable Amazon ECS to roll back the service if a service deployment fails. If rollback is enabled, when a service deployment fails, the service is rolled back to the last deployment that completed successfully.
    - cluster_name: (string) Cluster name
    - entry_point: (optional, list((string)) The entry point that's passed to the container. This parameter maps to Entrypoint in the docker container create command and the - entrypoint option to docker run.
    - command: (optional, list((string)) The command that's passed to the container. This parameter maps to Cmd in the docker container create command and the COMMAND parameter to docker run. If there are multiple arguments, each argument is a separated string in the array.

    - autoscaling: optional(object({
      - max_capacity: (number) Max capacity of the scalable target.
      - min_capacity: (number) Min capacity of the scalable target.
      - target_value: (number) Target value for the metric.
      - scale_in_cooldown: (number) Amount of time, in seconds, after a scale in activity completes before another scale in activity can start.
      - scale_out_cooldown: (number) Amount of time, in seconds, after a scale out activity completes before another scale out activity can start.
    }))
  EOF
}

variable "launch_type" {
  description = "Launch type for ECS Service (only if you use `launch_type` in compute_configuration)"
  type = string
  default = "FARGATE"
}

variable "compute_configuration" {
  description = "launch_type (FARGATE) or capacity_providers (FARGATE, FARGATE_SPOT)"
  type = string
  default = "launch_type"  # "launch_type" or "capacity_providers"
}

variable "capacity_provider_strategy" {
  description = <<EOF
    Strategy to use FARGATE o FARGATE_SPOT as capacity providers
      - capacity_provider: (string) Short name of the capacity provider.
      - base: (number) Number of tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined.
      - weight: (number) Relative percentage of the total number of launched tasks that should use the specified capacity provider.
  EOF
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
  ] 
}
