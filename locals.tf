locals {
  # Generar nombres de recursos siguiendo la convención de nomenclatura estándar
  service_names = {
    for k, v in var.ecs_services : k => "${var.client}-${var.project}-${var.environment}-ecs-service-${k}"
  }

  task_definition_names = {
    for k, v in var.ecs_services : k => "${var.client}-${var.project}-${var.environment}-task-${k}"
  }

  log_group_names = {
    for k, v in var.ecs_services : k => "/aws/ecs/${var.client}-${var.project}-${var.environment}-${k}"
  }

  # Validar dependencias entre contenedores
  # Esta estructura se usa para verificar que las dependencias entre contenedores sean válidas
  container_dependencies_validation = {
    for service_key, service in var.ecs_services : service_key => {
      for container_key, container in service.containers : container_key => {
        valid_dependencies = [
          for dep in container.depends_on : 
          contains(keys(service.containers), dep.container_name)
        ]
      }
    }
  }
}
