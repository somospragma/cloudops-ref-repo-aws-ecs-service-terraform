# Ejemplo de implementación del módulo cloudops-ref-repo-aws-ecs-service-terraform: Integración con Datadog

Este ejemplo demuestra cómo implementar un servicio ECS con integración a Datadog utilizando el módulo de referencia `cloudops-ref-repo-aws-ecs-service-terraform`. El ejemplo configura un servicio ECS que ejecuta una aplicación principal junto con un contenedor sidecar para la recolección y envío de métricas y logs a Datadog.

## Estructura de archivos

```
datadog-integration/
├── README.md                 # Esta documentación
├── main.tf                   # Configuración principal que llama al módulo
├── providers.tf              # Configuración de proveedores AWS
├── variables.tf              # Definición de variables
└── terraform.tfvars.example  # Ejemplo de valores de variables
```

## Requisitos previos

Para ejecutar este ejemplo, necesitas:

- Terraform v1.10.0 o superior
- AWS CLI configurado con las credenciales adecuadas
- Permisos IAM para:
  - Crear y gestionar servicios ECS
  - Crear y gestionar definiciones de tareas ECS
  - Crear y gestionar grupos de logs de CloudWatch
  - Acceder a subredes y grupos de seguridad VPC
  - Acceder a AWS Secrets Manager (para almacenar la API key de Datadog)
- Un cluster ECS existente
- Roles IAM para la ejecución y las tareas de ECS
- Subredes y grupos de seguridad configurados
- Una imagen de contenedor disponible en un registro (ECR, Docker Hub, etc.)
- Una cuenta de Datadog y una API key

## Cómo usar este ejemplo

### Preparación de variables

1. Almacena tu API key de Datadog en AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
    --name datadog/api-key \
    --secret-string '{"apikey":"tu-api-key-de-datadog"}'
```

2. Revisa y actualiza el archivo `terraform.tfvars` con tus valores específicos:

```hcl
client      = "tu-cliente"
project     = "tu-proyecto"
environment = "dev"

ecs_services = {
  "api" = {
    cluster_name    = "tu-cluster-ecs"
    desired_count   = 2
    task_cpu        = 1024
    task_memory     = 2048
    subnets         = ["subnet-12345678", "subnet-87654321"]
    security_groups = ["sg-12345678"]
    execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
    task_role_arn      = "arn:aws:iam::123456789012:role/ecsTaskRole"
    
    # Resto de la configuración...
  }
}
```

### Inicialización de Terraform

3. Inicializa Terraform para descargar los proveedores necesarios:

```bash
terraform init
```

### Verificación del plan

4. Genera un plan de ejecución para verificar los cambios que se realizarán:

```bash
terraform plan
```

### Aplicación de la configuración

5. Aplica la configuración para crear los recursos:

```bash
terraform apply
```

6. Confirma la creación de recursos escribiendo `yes` cuando se te solicite.

### Verificación de recursos creados

7. Una vez completado el despliegue, verifica los recursos creados:

```bash
# Verificar el servicio ECS
aws ecs describe-services --cluster tu-cluster-ecs --services tu-cliente-tu-proyecto-dev-service-api

# Verificar los logs en CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/aws/ecs/tu-cliente-tu-proyecto-dev"
```

8. Verifica que los datos se estén enviando a Datadog:
   - Accede a la consola de Datadog
   - Ve a Infrastructure > Containers para ver los contenedores monitoreados
   - Ve a Logs > Search para verificar que los logs se estén recibiendo
   - Ve a Metrics > Explorer para verificar que las métricas se estén recibiendo

## Escenarios incluidos

### Servicio ECS con agente Datadog como sidecar

Este ejemplo configura un servicio ECS con un contenedor principal y un contenedor sidecar para Datadog:

```hcl
ecs_services = {
  "api" = {
    cluster_name    = "tu-cluster-ecs"
    desired_count   = 2
    task_cpu        = 1024
    task_memory     = 2048
    subnets         = ["subnet-12345678", "subnet-87654321"]
    security_groups = ["sg-12345678"]
    execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
    task_role_arn      = "arn:aws:iam::123456789012:role/ecsTaskRole"
    
    containers = {
      "app" = {
        image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:latest"
        cpu   = 512
        memory = 1024
        port_mappings = [
          {
            container_port = 8080
          }
        ]
        environment = [
          {
            name  = "ENV"
            value = "development"
          }
        ]
        healthcheck = {
          command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
          interval    = 30
          timeout     = 5
          retries     = 3
          start_period = 60
        }
      },
      "datadog-agent" = {
        image = "public.ecr.aws/datadog/agent:latest"
        cpu   = 256
        memory = 512
        essential = true
        environment = [
          {
            name  = "DD_API_KEY"
            value = "{{resolve:secretsmanager:datadog/api-key:SecretString:apikey}}"
          },
          {
            name  = "DD_SITE"
            value = "datadoghq.com"
          },
          {
            name  = "DD_ECS_COLLECT_RESOURCE_TAGS_EC2"
            value = "true"
          },
          {
            name  = "DD_APM_ENABLED"
            value = "true"
          },
          {
            name  = "DD_LOGS_ENABLED"
            value = "true"
          },
          {
            name  = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL"
            value = "true"
          },
          {
            name  = "DD_CONTAINER_EXCLUDE"
            value = "name:datadog-agent"
          }
        ]
      }
    }
    
    load_balancer = {
      target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/api/abcdef1234567890"
      container_name   = "app"
      container_port   = 8080
    }
    
    log_retention_days = 30
  }
}
```

### Servicio ECS con FireLens para envío de logs a Datadog

Este ejemplo configura un servicio ECS con FireLens para enviar logs a Datadog:

```hcl
ecs_services = {
  "api" = {
    # Configuración básica...
    
    containers = {
      "app" = {
        image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:latest"
        # Otras configuraciones...
        
        log_configuration = {
          log_driver = "awsfirelens"
          options = {
            "Name"       = "datadog"
            "Host"       = "http-intake.logs.datadoghq.com"
            "TLS"        = "on"
            "dd_service" = "api"
            "dd_source"  = "nodejs"
            "dd_tags"    = "env:dev,project:api"
            "provider"   = "ecs"
          }
          secret_options = [
            {
              name       = "apikey"
              value_from = "arn:aws:secretsmanager:us-east-1:123456789012:secret:datadog/api-key:SecretString:apikey"
            }
          ]
        }
      },
      "log_router" = {
        image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
        essential = true
        cpu = 32
        memory = 64
        firelens_configuration = {
          type = "fluentbit"
          options = {
            "enable-ecs-log-metadata" = "true"
          }
        }
      }
    }
  }
}
```

## Flujos de trabajo recomendados

### Configuración de APM (Application Performance Monitoring)

Para habilitar el APM de Datadog en tu aplicación:

1. Configura las variables de entorno necesarias en el contenedor de la aplicación:

```hcl
environment = [
  {
    name  = "DD_AGENT_HOST"
    value = "localhost"
  },
  {
    name  = "DD_TRACE_AGENT_PORT"
    value = "8126"
  },
  {
    name  = "DD_SERVICE"
    value = "api"
  },
  {
    name  = "DD_ENV"
    value = "development"
  },
  {
    name  = "DD_VERSION"
    value = "1.0.0"
  }
]
```

2. Asegúrate de que el agente de Datadog tenga habilitado el APM:

```hcl
environment = [
  # Otras variables...
  {
    name  = "DD_APM_ENABLED"
    value = "true"
  },
  {
    name  = "DD_APM_NON_LOCAL_TRAFFIC"
    value = "true"
  }
]
```

3. Instrumenta tu aplicación con la biblioteca de rastreo de Datadog correspondiente a tu lenguaje de programación.

### Actualización de la versión del agente Datadog

Para actualizar la versión del agente Datadog:

1. Actualiza la referencia de la imagen en `terraform.tfvars`:

```hcl
containers = {
  "datadog-agent" = {
    image = "public.ecr.aws/datadog/agent:7.42.0"  # Especifica la versión deseada
    # Resto de la configuración...
  }
}
```

2. Aplica los cambios:

```bash
terraform apply
```

## Integración con otros servicios AWS

### Integración con AWS X-Ray y Datadog

Para integrar AWS X-Ray con Datadog:

1. Configura el agente de Datadog para recopilar trazas de X-Ray:

```hcl
environment = [
  # Otras variables...
  {
    name  = "DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT"
    value = "0.0.0.0:4317"
  },
  {
    name  = "DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_HTTP_ENDPOINT"
    value = "0.0.0.0:4318"
  }
]
```

2. Configura tu aplicación para enviar trazas a través de OpenTelemetry.

### Integración con CloudWatch Metrics y Datadog

Para enviar métricas de CloudWatch a Datadog:

1. Configura la integración de CloudWatch en tu cuenta de Datadog
2. Asegúrate de que el rol de IAM tenga permisos para leer métricas de CloudWatch:

```hcl
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:Get*",
        "cloudwatch:List*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
```

## Solución de problemas comunes

### El agente de Datadog no envía datos

**Problema**: El agente de Datadog está en ejecución pero no se ven datos en la consola de Datadog.

**Solución**:
1. Verifica que la API key sea correcta:
   ```bash
   aws secretsmanager get-secret-value --secret-id datadog/api-key
   ```
2. Verifica que el agente tenga acceso a Internet para enviar datos a Datadog
3. Revisa los logs del agente:
   ```bash
   aws logs get-log-events --log-group-name "/aws/ecs/tu-cliente-tu-proyecto-dev" --log-stream-name "datadog-agent/datadog-agent/[ID]"
   ```

### Problemas con FireLens

**Problema**: Los logs no se están enviando a Datadog a través de FireLens.

**Solución**:
1. Verifica que el contenedor `log_router` esté en ejecución
2. Asegúrate de que la configuración de FireLens sea correcta
3. Revisa los logs del contenedor `log_router`:
   ```bash
   aws logs get-log-events --log-group-name "/aws/ecs/tu-cliente-tu-proyecto-dev" --log-stream-name "firelens/log_router/[ID]"
   ```
4. Verifica que el secreto de la API key sea accesible para el contenedor

## Limpieza

Para eliminar todos los recursos creados por este ejemplo:

1. Ejecuta el comando de destrucción de Terraform:

```bash
terraform destroy
```

2. Confirma la eliminación escribiendo `yes` cuando se te solicite.

3. Verifica que los recursos se hayan eliminado correctamente:

```bash
# Verificar que el servicio ECS ya no existe
aws ecs describe-services --cluster tu-cluster-ecs --services tu-cliente-tu-proyecto-dev-service-api

# Verificar que los grupos de logs se hayan eliminado
aws logs describe-log-groups --log-group-name-prefix "/aws/ecs/tu-cliente-tu-proyecto-dev"
```

4. Opcionalmente, elimina el secreto de Datadog si ya no lo necesitas:

```bash
aws secretsmanager delete-secret --secret-id datadog/api-key --force-delete-without-recovery
```

**Nota importante**: La eliminación de los grupos de logs de CloudWatch puede requerir pasos adicionales si has configurado una política de retención. Asegúrate de verificar que todos los recursos se hayan eliminado correctamente para evitar cargos inesperados.
