# **Módulo Terraform: cloudops-ref-repo-aws-ecs-service-terraform**

## Descripción:

Este módulo facilita la creación de los siguientes recursos en AWS:

- Crear Task definition
- Crear ECS service
- Crear ECS Log group
- Crear AutoScaling ScalableTarget
- Crear AutoScaling Policy

Consulta CHANGELOG.md para la lista de cambios de cada versión. *Recomendamos encarecidamente que en tu código fijes la versión exacta que estás utilizando para que tu infraestructura permanezca estable y actualices las versiones de manera sistemática para evitar sorpresas.*

## Estructura del Módulo
El módulo cuenta con la siguiente estructura:

```bash
cloudops-ref-repo-aws-ecs_service-terraform/
└── sample/ecs_service
    ├── data.tf
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    ├── terraform.tfvars.sample
    └── variables.tf
├── .gitignore
├── CHANGELOG.md
├── data.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── README.md
├── variables.tf
```

- Los archivos principales del módulo (`data.tf`, `main.tf`, `outputs.tf`, `variables.tf`, `providers.tf`) se encuentran en el directorio raíz.
- `CHANGELOG.md` y `README.md` también están en el directorio raíz para fácil acceso.
- La carpeta `sample/` contiene un ejemplo de implementación del módulo.

## Seguridad & Cumplimiento
 
Consulta a continuación la fecha y los resultados de nuestro escaneo de seguridad y cumplimiento.
 
<!-- BEGIN_BENCHMARK_TABLE -->
| Benchmark | Date | Version | Description | 
| --------- | ---- | ------- | ----------- | 
| ![checkov](https://img.shields.io/badge/checkov-passed-green) | 2023-09-20 | 3.2.232 | Escaneo profundo del plan de Terraform en busca de problemas de seguridad y cumplimiento |
<!-- END_BENCHMARK_TABLE -->

## Provider Configuration

Este módulo requiere la configuración de un provider específico para el proyecto. Debe configurarse de la siguiente manera:

```hcl
sample/ecs_service/providers.tf
provider "aws" {
  alias = "alias01"
  # ... otras configuraciones del provider
}

sample/ecs_service/main.tf
module "ecs_service" {
  source = ""
  providers = {
    aws.project = aws.alias01
  }
  # ... resto de la configuración
}
```

## Uso del Módulo:

```hcl
module "ecs_service" {
  source = ""
  
  providers = {
    aws.project = aws.project
  }

  # Common configuration
  client        = "example"
  project       = "example"
  environment   = "dev"
  aws_region    = "us-east-1"
  common_tags = {
      environment   = "dev"
      project-name  = "proyecto01"
      cost-center   = "xxx"
      owner         = "xxx"
      area          = "xxx"
      provisioned   = "xxx"
      datatype      = "xxx"
  }

  # ECS Service configuration

}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.31.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.project"></a> [aws.project](#provider\_aws) | >= 4.31.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_cloudwatch_log_group.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_appautoscaling_target.ecs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_appautoscaling_policy.ecs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |


## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="execution_role_arn"></a> [execution_role_arn](#input\execution_role_arn) | ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. | `string` | n/a | yes |
| <a name="task_role_arn"></a> [task_role_arn](#input\task_role_arn) | ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services. | `string` | n/a | yes |
| <a name="network_mode"></a> [network_mode](#input\network_mode) | Docker networking mode to use for the containers in the task. Valid values are none, bridge, awsvpc, and host. | `string` | n/a | yes |
| <a name="image_version"></a> [image_version](#input\image_version) | Version of ECR image. | `string` | n/a | yes |
| <a name="memory"></a> [memory](#input\memory) | Amount (in MiB) of memory used by the task. If the requires_compatibilities is FARGATE this field is required. | `number` | n/a | yes |
| <a name="cpu"></a> [cpu](#input\cpu) | Number of cpu units used by the task. If the requires_compatibilities is FARGATE this field is required. | `number` | n/a | yes |
| <a name="cpu_container"></a> [cpu_container](#input\cpu_container) | The number of cpu units reserved for the container. | `number` | n/a | yes |
| <a name="requires_compatibilities"></a> [requires_compatibilities](#input\requires_compatibilities) | Set of launch types required by the task. The valid values are EC2 and FARGATE. | `list(string)` | n/a | yes |
| <a name="portMappings.containerPort"></a> [portMappings.containerPort](#input\portMappings.containerPort) | Port on the container to associate with the load balancer. | `number` | n/a | yes |
| <a name="portMappings.hostPort"></a> [portMappings.hostPort](#input\portMappings.hostPort) | For task definitions that use the awsvpc network mode, only specify the containerPort. The hostPort can be left blank or it must be the same value as the containerPort. | `number` | n/a | yes |
| <a name="environmentFiles.value"></a> [environmentFiles.value](#input\environmentFiles.value) | Environment value | `string` | n/a | yes |
| <a name="environmentFiles.type"></a> [environmentFiles.type](#input\environmentFiles.type) | Environment type | `string` | n/a | yes |
| <a name="environment_variables.name"></a> [environment_variables.name](#input\environment_variables.name) | Environment name | `string` | n/a | yes |
| <a name="environment_variables.value"></a> [environment_variables.value](#input\environment_variables.value) | Environment value | `string` | n/a | yes |
| <a name="functionality"></a> [functionality](#input\functionality) | Functionality name | `string` | n/a | yes |
| <a name="image"></a> [image](#input\image) | URL of ECR image. | `string` | n/a | yes |
| <a name="volumes.read_only"></a> [volumes.read_only](#input\volumes.read_only) | If this value is true, the container has read-only access to the volume. If this value is false, then the container can write to the volume. The default value is false. | `bool` | n/a | yes |
| <a name="volumes.volume_name"></a> [volumes.volume_name](#input\volumes.volume_name) | The name of the volume to mount. Must be a volume name referenced in the name parameter of task definition volume. | `string` | n/a | yes |
| <a name="volumes.container_path"></a> [volumes.container_path](#input\volumes.container_path) | The path on the container to mount the host volume at. | `string` | n/a | yes |
| <a name="volumes.file_system_id"></a> [volumes.file_system_id](#input\volumes.file_system_id) | ID of the EFS File System. | `string` | n/a | yes |
| <a name="volumes.transit_encryption"></a> [volumes.transit_encryption](#input\volumes.transit_encryption) | Whether or not to enable encryption for Amazon EFS data in transit between the Amazon ECS host and the Amazon EFS server. Transit encryption must be enabled if Amazon EFS IAM authorization is used. Valid values: ENABLED, DISABLED. If this parameter is omitted, the default value of DISABLED is used. | `string` | n/a | yes |
| <a name="volumes.access_point_id"></a> [volumes.access_point_id](#input\volumes.access_point_id) | Access point ID to use. If an access point is specified, the root directory value will be relative to the directory set for the access point. If specified, transit encryption must be enabled in the EFSVolumeConfiguration. | `string` | n/a | yes |
| <a name="runtime_platform.operating_system_family"></a> [runtime_platform.operating_system_family](#input\runtime_platform.operating_system_family) | If the requires_compatibilities is FARGATE this field is required; must be set to a valid option from the operating system family in the runtime platform setting | `string` | n/a | yes |
| <a name="runtime_platform.cpu_architecture"></a> [runtime_platform.cpu_architecture](#input\runtime_platform.cpu_architecture) | Must be set to either X86_64 or ARM64. | `string` | n/a | yes |
| <a name="secrets.name"></a> [secrets.name](#input\secrets.name) | Secret name | `string` | n/a | yes |
| <a name="secrets.arn"></a> [secrets.arn](#input\secrets.arn) | The secret to expose to the container. The supported values are either the full ARN of the AWS Secrets Manager secret or the full ARN of the parameter in the SSM Parameter Store. | `string` | n/a | yes |
| <a name="parameters.name"></a> [parameters.name](#input\parameters.name) | Parameter name | `string` | n/a | yes |
| <a name="parameters.arn"></a> [parameters.arn](#input\parameters.arn) | PENDING | `string` | n/a | yes |
| <a name="desired_count"></a> [desired_count](#input\desired_count) | Number of instances of the task definition to place and keep running. Defaults to 0. Do not specify if using the DAEMON scheduling strategy.  | `number` | n/a | yes |
| <a name="health_check_grace_period_seconds"></a> [health_check_grace_period_seconds](#input\health_check_grace_period_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers. | `number` | n/a | yes |
| <a name="target_group_arn"></a> [target_group_arn](#input\target_group_arn) | ARN of the Load Balancer target group to associate with the service. | `string` | n/a | yes |
| <a name="security_groups"></a> [security_groups](#input\security_groups) | Security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used. | `list(string)` | n/a | yes |
| <a name="subnets"></a> [subnets](#input\subnets) | Subnets associated with the task or service. | `list(string)` | n/a | yes |
| <a name="assign_public_ip"></a> [assign_public_ip](#input\assign_public_ip) | Assign a public IP address to the ENI (Fargate launch type only). Valid values are true or false. Default false. | `string` | n/a | yes |
| <a name="enable_rollback"></a> [enable_rollback](#input\enable_rollback) | Whether to enable the deployment circuit breaker logic for the service. | `string` | n/a | yes |
| <a name="rollback"></a> [rollback](#input\rollback) | Whether to enable Amazon ECS to roll back the service if a service deployment fails. If rollback is enabled, when a service deployment fails, the service is rolled back to the last deployment that completed successfully. | `string` | n/a | yes |
| <a name="cluster_name"></a> [cluster_name](#input\cluster_name) | Cluster name | `string` | n/a | yes |
| <a name="entry_point"></a> [entry_point](#input\entry_point) | The entry point that's passed to the container. This parameter maps to Entrypoint in the docker container create command and the - entrypoint option to docker run. | `string` | n/a | no |
| <a name="command"></a> [command](#input\command) | The command that's passed to the container. This parameter maps to Cmd in the docker container create command and the COMMAND parameter to docker run. If there are multiple arguments, each argument is a separated string in the array. | `string` | n/a | no |
| <a name="autoscaling.max_capacity"></a> [autoscaling.max_capacity](#input\autoscaling.max_capacity) | Max capacity of the scalable target. | `number` | n/a | no |
| <a name="autoscaling.min_capacity"></a> [autoscaling.min_capacity](#input\autoscaling.min_capacity) | Min capacity of the scalable target. | `number` | n/a | no |
| <a name="autoscaling.target_value"></a> [autoscaling.target_value](#input\autoscaling.target_value) | Target value for the metric. | `number` | n/a | no |
| <a name="autoscaling.scale_in_cooldown"></a> [autoscaling.scale_in_cooldown](#input\autoscaling.scale_in_cooldown) | Amount of time, in seconds, after a scale in activity completes before another scale in activity can start. | `number` | n/a | no |
| <a name="autoscaling.scale_out_cooldown"></a> [autoscaling.scale_out_cooldown](#input\autoscaling.scale_out_cooldown) | Amount of time, in seconds, after a scale out activity completes before another scale out activity can start. | `number` | n/a | no |
| <a name="launch_type"></a> [launch_type](#input\launch_type) | Launch type | `string` | n/a | yes |
| <a name="compute_configuration"></a> [compute_configuration](#input\compute_configuration) | launch_type (FARGATE) or capacity_providers (FARGATE, FARGATE_SPOT) | `string` | n/a | yes |
| <a name="capacity_provider_strategy.capacity_provider"></a> [capacity_provider_strategy.capacity_provider](#input\capacity_provider_strategy.capacity_provider) | Short name of the capacity provider. | `string` | n/a | yes |
| <a name="capacity_provider_strategy.base"></a> [capacity_provider_strategy.base](#input\capacity_provider_strategy.base) | Number of tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined. | `number` | n/a | yes |
| <a name="capacity_provider_strategy.weight"></a> [capacity_provider_strategy.weight](#input\capacity_provider_strategy.weight) | Relative percentage of the total number of launched tasks that should use the specified capacity provider. | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="task_info.task_arn"></a> [task_info.task_arn](#output\task_info.task_arn) | Task ARN |
| <a name="task_info.task_id"></a> [task_info.task_id](#output\task_info.task_id) | Task ID |
