# Ejemplo: Servicio ECS para Comments API

Este ejemplo muestra cómo desplegar un servicio ECS para una API de comentarios con integración de Datadog para monitoreo.

## Arquitectura

Este ejemplo despliega:

- Un servicio ECS en un clúster existente
- Una tarea ECS con dos contenedores:
  - Contenedor principal `comments-api`: Aplicación Java Spring Boot
  - Contenedor sidecar `datadog-agent`: Agente de monitoreo Datadog
- Configuración de auto-scaling basada en CPU
- Integración con un balanceador de carga existente
- Configuración de secretos desde AWS Secrets Manager y parámetros desde SSM Parameter Store

## Requisitos previos

Para usar este ejemplo, necesitas tener:

1. Un clúster ECS existente (`Cluster_mapa-de-crecimiento`)
2. Roles IAM para la ejecución y tarea de ECS
3. Un repositorio ECR con la imagen de la aplicación
4. Un grupo de seguridad para el servicio ECS
5. Subredes en una VPC
6. Un target group en un balanceador de carga
7. Secretos en AWS Secrets Manager
8. Parámetros en AWS SSM Parameter Store
9. Una clave API de Datadog almacenada en Secrets Manager

## Uso

1. Copia `terraform.tfvars.example` a `terraform.tfvars`
2. Actualiza los valores en `terraform.tfvars` con tus propios recursos
3. Inicializa Terraform:

```bash
terraform init
```

4. Verifica el plan de Terraform:

```bash
terraform plan
```

5. Aplica la configuración:

```bash
terraform apply
```

## Personalización

Este ejemplo puede personalizarse modificando los siguientes aspectos:

- **Recursos de la tarea**: Ajusta `task_cpu` y `task_memory` según las necesidades de tu aplicación
- **Auto-scaling**: Modifica los valores de `min_capacity`, `max_capacity` y `target_value` para ajustar el comportamiento de escalado
- **Configuración de Datadog**: Ajusta las variables de entorno del agente Datadog según tus necesidades de monitoreo
- **Healthcheck**: Personaliza los parámetros de healthcheck para tu aplicación específica

## Notas importantes

- Este ejemplo asume que todos los recursos externos (clúster, roles, repositorios, etc.) ya existen
- Los ARNs y IDs en el ejemplo son ficticios y deben ser reemplazados con tus propios valores
- La configuración de Datadog está optimizada para aplicaciones Java Spring Boot, pero puede ajustarse para otros tipos de aplicaciones
