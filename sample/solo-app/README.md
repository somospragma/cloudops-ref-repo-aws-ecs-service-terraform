# Ejemplo de implementación del módulo cloudops-ref-repo-aws-ecs-service-terraform: Aplicación Simple

Este ejemplo demuestra cómo implementar un servicio ECS básico con un solo contenedor utilizando el módulo de referencia `cloudops-ref-repo-aws-ecs-service-terraform`. El ejemplo configura un servicio ECS que ejecuta una aplicación simple con logs enviados a CloudWatch.

## Estructura de archivos

```
solo-app/
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
- Un cluster ECS existente
- Roles IAM para la ejecución y las tareas de ECS
- Subredes y grupos de seguridad configurados
- Una imagen de contenedor disponible en un registro (ECR, Docker Hub, etc.)

## Cómo usar este ejemplo

### Preparación de variables

1. Revisa y actualiza el archivo `terraform.tfvars` con tus valores específicos:

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

2. Inicializa Terraform para descargar los proveedores necesarios:

```bash
terraform init
```

### Verificación del plan

3. Genera un plan de ejecución para verificar los cambios que se realizarán:

```bash
terraform plan
```

### Aplicación de la configuración

4. Aplica la configuración para crear los recursos:

```bash
terraform apply
```

5. Confirma la creación de recursos escribiendo `yes` cuando se te solicite.

### Verificación de recursos creados

6. Una vez completado el despliegue, verifica los recursos creados:

```bash
# Verificar el servicio ECS
aws ecs describe-services --cluster tu-cluster-ecs --services tu-cliente-tu-proyecto-dev-service-api

# Verificar los logs en CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/aws/ecs/tu-cliente-tu-proyecto-dev"
```

7. También puedes verificar los recursos a través de la consola AWS:
   - Accede a la consola de AWS
   - Ve a ECS > Clusters > tu-cluster-ecs > Services
   - Verifica que el servicio esté en estado "ACTIVE"
   - Ve a CloudWatch > Logs > Log groups para verificar los logs

## Escenarios incluidos

### Servicio ECS básico con un solo contenedor

Este ejemplo configura un servicio ECS básico con un solo contenedor que:

- Se ejecuta en Fargate
- Está conectado a un balanceador de carga
- Envía logs a CloudWatch
- Tiene configuración de healthcheck

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

## Flujos de trabajo recomendados

### Actualización de la imagen del contenedor

Para actualizar la imagen del contenedor a una nueva versión:

1. Actualiza la referencia de la imagen en `terraform.tfvars`:

```hcl
containers = {
  "app" = {
    image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:nueva-version"
    # Resto de la configuración...
  }
}
```

2. Aplica los cambios:

```bash
terraform apply
```

3. Verifica que el servicio se actualice correctamente:

```bash
aws ecs describe-services --cluster tu-cluster-ecs --services tu-cliente-tu-proyecto-dev-service-api
```

### Escalado del servicio

Para escalar el servicio a más o menos tareas:

1. Actualiza el `desired_count` en `terraform.tfvars`:

```hcl
ecs_services = {
  "api" = {
    desired_count = 4  # Aumentar de 2 a 4
    # Resto de la configuración...
  }
}
```

2. Aplica los cambios:

```bash
terraform apply
```

## Integración con otros servicios AWS

### Integración con CloudWatch Alarms

Puedes crear alarmas de CloudWatch para monitorear el servicio ECS:

```hcl
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Este alarma se activa cuando el uso de CPU supera el 80%"
  
  dimensions = {
    ClusterName = "tu-cluster-ecs"
    ServiceName = "tu-cliente-tu-proyecto-dev-service-api"
  }
  
  alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]
}
```

### Integración con AWS X-Ray

Para habilitar el rastreo con AWS X-Ray, añade el contenedor sidecar de X-Ray:

```hcl
containers = {
  "app" = {
    # Configuración existente...
  },
  "xray-daemon" = {
    image = "amazon/aws-xray-daemon"
    cpu   = 32
    memory = 256
    port_mappings = [
      {
        container_port = 2000
        protocol       = "udp"
      }
    ]
  }
}
```

## Solución de problemas comunes

### El servicio no puede extraer la imagen del contenedor

**Problema**: El servicio ECS no puede extraer la imagen del contenedor y muestra errores como "CannotPullContainerError".

**Solución**:
1. Verifica que el rol de ejecución tenga permisos para extraer imágenes del registro:
   ```bash
   aws iam get-role --role-name ecsTaskExecutionRole
   ```
2. Si usas ECR, asegúrate de que la imagen exista y que el formato sea correcto:
   ```bash
   aws ecr describe-images --repository-name api --image-ids imageTag=latest
   ```

### El contenedor falla el healthcheck

**Problema**: El contenedor falla repetidamente el healthcheck y el servicio no puede estabilizarse.

**Solución**:
1. Verifica que la ruta de healthcheck sea correcta y que la aplicación responda en esa ruta
2. Aumenta el `start_period` para dar más tiempo a la aplicación para inicializarse:
   ```hcl
   healthcheck = {
     command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
     interval    = 30
     timeout     = 5
     retries     = 3
     start_period = 120  # Aumentar a 120 segundos
   }
   ```

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

**Nota importante**: La eliminación de los grupos de logs de CloudWatch puede requerir pasos adicionales si has configurado una política de retención. Asegúrate de verificar que todos los recursos se hayan eliminado correctamente para evitar cargos inesperados.
