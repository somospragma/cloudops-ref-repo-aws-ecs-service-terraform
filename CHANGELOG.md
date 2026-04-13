# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-04-13

### Changed
- Agregado soporte para environment `prod` en la validación de variables
- La validación de environment ahora acepta: dev, qa, pdn, prod

## [1.0.0] - 2025-05-26

### Añadido
- Estructura inicial del módulo
- Soporte para creación de servicios ECS con múltiples contenedores
- Configuración de volúmenes EFS con cifrado en tránsito
- Integración con balanceadores de carga
- Auto-scaling basado en métricas de CloudWatch
- Monitoreo y observabilidad con logs de CloudWatch
- Configuración de alarmas para métricas críticas
- Etiquetado consistente según estándares organizacionales
- Validaciones de entrada para prevenir configuraciones incorrectas
- Soporte para contenedores sidecar
- Configuración de healthchecks para contenedores
- Documentación completa con ejemplos de uso
- Soporte para AWS ECS Service Connect
- Documentación sobre Service Connect en docs/service-connect.md
- Ejemplo de implementación con Service Connect en terraform.auto.tfvars.sample
- Soporte para nombres de puerto en port_mappings para Service Connect
