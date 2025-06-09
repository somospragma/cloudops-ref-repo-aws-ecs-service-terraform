# Reglas para Módulos de Referencia Terraform

Este documento establece las reglas y estándares específicos para la creación de módulos de referencia Terraform en nuestra organización, basados en la experiencia práctica de implementación. Incluye ejemplos concretos y explicaciones detalladas para cada aspecto importante.

## 1. Estructura de Directorios

Todo módulo de referencia debe seguir esta estructura de directorios:

```
modulo-referencia/
├── .gitignore                # Archivos a ignorar por Git
├── CHANGELOG.md              # Registro de cambios del módulo
├── README.md                 # Documentación principal
├── data.tf                   # Recursos de datos
├── main.tf                   # Recursos principales
├── outputs.tf                # Salidas del módulo
├── providers.tf              # Configuración de proveedores
├── variables.tf              # Variables de entrada
├── sample/                   # Directorio con ejemplo de uso
│   ├── README.md             # Documentación del ejemplo
│   ├── data.tf               # Recursos de datos del ejemplo
│   ├── main.tf               # Configuración principal del ejemplo
│   ├── outputs.tf            # Salidas del ejemplo
│   ├── providers.tf          # Configuración de proveedores del ejemplo
│   ├── terraform.auto.tfvars.sample # Ejemplo de variables
│   └── variables.tf          # Variables del ejemplo
└── modules/                  # Submódulos (opcional)
    └── ...
```

## 2. Convenciones de Nomenclatura

### 2.1 Regla General

Todos los recursos de infraestructura deben seguir el estándar:
```
{client}-{project}-{environment}-resource-type-{name}
```

### 2.2 Implementación en Código

Utiliza bloques `locals` para generar nombres consistentes:

```hcl
locals {
  # Generar nombres de recursos siguiendo la convención de nomenclatura estándar
  certificate_names = {
    for k, v in var.certificates_config : k => "${var.client}-${var.project}-${var.environment}-acm-${k}"
  }
}

resource "aws_acm_certificate" "certificate" {
  for_each = var.certificates_config
  name     = local.certificate_names[each.key]
  # Resto de la configuración...
}
```

## 3. Sistema de Etiquetado (Tagging)

### 3.1 Enfoque de Etiquetado

El sistema de etiquetado se implementa en tres niveles:

1. **Etiquetas Transversales**: Definidas a nivel del proveedor AWS usando `default_tags`
2. **Etiquetas Específicas del Módulo**: Definidas en la variable `additional_tags` del módulo
3. **Etiquetas Específicas del Recurso**: Definidas en la propiedad `additional_tags` de cada recurso

### 3.2 Etiquetas Transversales Obligatorias

Las etiquetas transversales se definen en el archivo `providers.tf` del consumidor del módulo:

```hcl
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      environment = var.environment
      project     = var.project
      owner       = "cloudops"
      client      = var.client
      area        = "infrastructure"
      provisioned = "terraform"
      datatype    = "operational"
    }
  }
}
```

### 3.3 Etiquetas Específicas del Módulo

Se definen en la variable `additional_tags` del módulo:

```hcl
variable "additional_tags" {
  description = "Etiquetas adicionales para todos los recursos creados por el módulo"
  type        = map(string)
  default     = {}
}
```

### 3.4 Etiquetas Específicas del Recurso

Se definen dentro de la configuración de cada recurso:

```hcl
variable "certificates_config" {
  description = "Configuración de certificados en AWS Certificate Manager"
  type = map(object({
    # Otras propiedades...
    
    # Etiquetas específicas para este certificado
    additional_tags = optional(map(string), {})
  }))
}
```

### 3.5 Aplicación de Etiquetas en Recursos

Las etiquetas se aplican a los recursos usando la función `merge`:

```hcl
resource "aws_acm_certificate" "certificate" {
  # Otras configuraciones...
  
  tags = merge(
    {
      Name = local.certificate_names[each.key]
    },
    var.additional_tags,
    each.value.additional_tags
  )
}
```

### 3.6 Jerarquía de Etiquetas

1. Las etiquetas definidas en `default_tags` se aplican a todos los recursos
2. Las etiquetas en `additional_tags` del módulo se aplican a todos los recursos creados por el módulo
3. Las etiquetas específicas en `additional_tags` de cada recurso tienen prioridad sobre las anteriores
4. La etiqueta `Name` debe generarse siempre según la convención de nomenclatura

## 4. Uso de Mapas de Objetos para Recursos

### 4.1 Patrón Recomendado

Utiliza mapas de objetos para configuraciones de recursos en lugar de listas:

```hcl
# RECOMENDADO: Usar mapas de objetos para recursos
variable "certificates_config" {
  description = "Configuración de certificados en AWS Certificate Manager"
  type = map(object({
    # Propiedades del certificado...
  }))
}

# Implementación con for_each
resource "aws_acm_certificate" "certificate" {
  for_each = var.certificates_config
  
  domain_name = each.value.domain_name
  # Otras configuraciones...
}
```

### 4.2 Ventajas de los Mapas de Objetos

- Facilita la referencia a recursos específicos por clave
- Previene problemas con el índice cuando se eliminan elementos del medio de una lista
- Permite actualizaciones y modificaciones más seguras
- Mejora la legibilidad y mantenibilidad del código
- Facilita la adición o eliminación de recursos sin afectar a otros

### 4.3 Uso de `for_each` vs `count`

Siempre usa `for_each` en lugar de `count` para recursos con claves únicas:

```hcl
# RECOMENDADO: Usar for_each con mapas
resource "aws_acm_certificate_validation" "validation" {
  for_each = {
    for k, v in var.certificates_config : k => v
    if v.wait_for_validation == true
  }
  
  certificate_arn = aws_acm_certificate.certificate[each.key].arn
  # Otras configuraciones...
}

# NO RECOMENDADO: Usar count con listas
resource "aws_acm_certificate_validation" "validation" {
  count = length([for cert in var.certificates_list if cert.wait_for_validation])
  
  certificate_arn = aws_acm_certificate.certificate[count.index].arn
  # Otras configuraciones...
}
```

## 5. Transformaciones con `locals`

### 5.1 Uso de `locals` para Transformaciones

Implementa `locals` para transformaciones y cálculos internos:

```hcl
locals {
  # Generar nombres estandarizados para los certificados
  certificate_names = {
    for k, v in var.certificates_config : k => "${var.client}-${var.project}-${var.environment}-acm-${k}"
  }
  
  # Filtrar certificados que requieren validación
  certificates_with_validation = {
    for k, v in var.certificates_config : k => v
    if v.wait_for_validation == true
  }
}
```

### 5.2 Transformaciones Complejas

Para transformaciones complejas, usa expresiones `for` anidadas:

```hcl
locals {
  # Crear una estructura para los registros DNS de validación
  dns_validation_records = {
    for cert_key, cert in aws_acm_certificate.certificate : cert_key => [
      for dvo in cert.domain_validation_options : {
        domain = dvo.domain_name
        name   = dvo.resource_record_name
        type   = dvo.resource_record_type
        value  = dvo.resource_record_value
      } if cert.validation_method == "DNS"
    ]
  }
}
```

## 6. Validación de Variables

### 6.1 Validaciones Básicas

Implementa validación de variables con reglas de validación:

```hcl
variable "environment" {
  description = "Entorno en el que se desplegarán los certificados (dev, qa, pdn)"
  type        = string
  
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}
```

### 6.2 Validaciones Complejas

Para validaciones más complejas, usa la función `alltrue`:

```hcl
variable "certificates_config" {
  # Definición de tipo...
  
  validation {
    condition = alltrue([
      for k, v in var.certificates_config : 
      contains(["DNS", "EMAIL"], v.validation_method)
    ])
    error_message = "El método de validación debe ser 'DNS' o 'EMAIL'."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.certificates_config : 
      contains(["RSA_1024", "RSA_2048", "RSA_4096", "EC_prime256v1", "EC_secp384r1"], v.key_algorithm)
    ])
    error_message = "El algoritmo de clave debe ser uno de: 'RSA_1024', 'RSA_2048', 'RSA_4096', 'EC_prime256v1', 'EC_secp384r1'."
  }
}
```

## 7. Configuración de Proveedores

### 7.1 Definición de Proveedores con Alias

Los módulos deben utilizar alias para los proveedores:

```hcl
# En el módulo (providers.tf)
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.31.0"
      configuration_aliases = [aws.project]
    }
  }
}

# Uso del proveedor con alias en recursos
resource "aws_acm_certificate" "certificate" {
  provider = aws.project
  # Resto de la configuración...
}
```

### 7.2 Mapeo de Proveedores al Llamar al Módulo

```hcl
# En el archivo providers.tf del consumidor
module "acm" {
  source = "../"
  
  providers = {
    aws.project = aws.principal
  }
  
  # Resto de la configuración...
}
```

## 8. Estructura de Documentación

### 8.1 README.md Principal

El README.md principal debe seguir esta estructura estandarizada:

1. **Título**
   - Nombre del módulo con formato "Módulo Terraform: nombre-del-módulo"

2. **Descripción**
   - Descripción concisa del propósito y funcionalidad del módulo
   - Referencia al CHANGELOG.md para ver historial de cambios
   - Recomendación de fijar versiones específicas

3. **Diagrama de Arquitectura** (si aplica)
   - Representación visual de la arquitectura implementada por el módulo

4. **Características**
   - Lista de características principales con marcas de verificación (✅)

5. **Estructura del Módulo**
   - Descripción de la organización de archivos y directorios

6. **Implementación y Configuración**
   - **Requisitos Técnicos**: Tablas de versiones de Terraform y providers
   - **Provider Configuration**: Ejemplo de configuración del provider
   - **Configuración del Backend**: Recomendaciones para configurar el backend
   - **Convenciones de nomenclatura**: Estándares de nombres de recursos
   - **Estrategia de Etiquetado**: Explicación del sistema de etiquetado
   - **Recursos Gestionados**: Tabla de recursos creados por el módulo
   - **Parámetros de Entrada**: Tabla de variables con descripciones
   - **Estructura de Configuración**: Detalle de estructuras de datos complejas
   - **Valores de Salida**: Tabla de outputs con descripciones
   - **Ejemplos de Uso**: Fragmentos de código con ejemplos básicos

7. **Escenarios de Uso Comunes**
   - Ejemplos de casos de uso típicos con configuraciones específicas
   - Flujos de trabajo recomendados para diferentes escenarios

8. **Consideraciones Operativas**
   - **Rendimiento y Escalabilidad**: Información sobre límites y optimizaciones
   - **Limitaciones y Restricciones**: Advertencias sobre limitaciones conocidas
   - **Costos y Optimización**: Información sobre costos y estrategias de optimización
   - **Recomendaciones de Implementación**: Mejores prácticas para implementar el módulo

9. **Seguridad y Cumplimiento**
   - **Consideraciones de seguridad**: Recomendaciones de seguridad específicas
   - **Análisis de Seguridad**: Resultados de escaneos de seguridad (KICS, CHECKOV)
   - **Mejores Prácticas Implementadas**: Lista de prácticas de seguridad aplicadas
   - **Lista de Verificación de Cumplimiento**: Checklist de requisitos cumplidos

10. **Observaciones**
    - Notas adicionales, advertencias o información importante
    - Consejos para casos de uso específicos

### 8.2 Formato de Tablas en README

Las tablas de documentación deben seguir este formato:

```markdown
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [input_name](#input\input_name) | Descripción de la variable | `string` | `"default"` | no |
```

Para outputs:

```markdown
| Name | Description |
|------|-------------|
| <a name="output_name"></a> [output_name](#output\output_name) | Descripción del output |
```

### 8.3 README.md del Directorio Sample

El README.md del directorio sample debe seguir esta estructura estandarizada:

1. **Título y Descripción**
   - Nombre del ejemplo con formato "Ejemplo de implementación del módulo [nombre-del-módulo]"
   - Breve descripción del propósito del ejemplo

2. **Estructura de archivos**
   - Lista de los archivos incluidos en el directorio sample y su propósito

3. **Requisitos previos**
   - Lista de requisitos necesarios para ejecutar el ejemplo:
     - Versión de Terraform
     - AWS CLI configurado
     - Permisos IAM necesarios
     - Otros requisitos específicos

4. **Cómo usar este ejemplo**
   - Instrucciones paso a paso para implementar el ejemplo:
     - Preparación de variables
     - Inicialización de Terraform
     - Verificación del plan
     - Aplicación de la configuración
     - Verificación de recursos creados

5. **Escenarios incluidos**
   - Descripción detallada de los diferentes escenarios de uso demostrados en el ejemplo
   - Código de ejemplo para cada escenario
   - Explicación del flujo de trabajo para cada escenario

6. **Flujos de trabajo recomendados**
   - Guías paso a paso para completar tareas comunes
   - Comandos específicos a ejecutar
   - Verificación de resultados

7. **Integración con otros servicios AWS**
   - Ejemplos de cómo usar los recursos creados con diferentes servicios AWS
   - Fragmentos de código para la integración

8. **Solución de problemas comunes** (opcional)
   - Lista de problemas frecuentes y sus soluciones
   - Errores comunes y cómo resolverlos

9. **Limpieza**
   - Instrucciones para eliminar los recursos creados
   - Consideraciones especiales para la limpieza

### 8.4 Documentación de Variables y Outputs

#### 8.4.1 Documentación de Variables

Todas las variables deben estar documentadas con descripciones claras:

```hcl
variable "certificates_config" {
  description = "Configuración de certificados en AWS Certificate Manager"
  type = map(object({
    domain_name               = string  # Nombre de dominio principal para el certificado
    subject_alternative_names = optional(list(string), [])  # Lista de nombres de dominio alternativos
    validation_method         = string  # Método de validación ("DNS" o "EMAIL")
    # Más propiedades con comentarios...
  }))
}
```

#### 8.4.2 Documentación de Outputs

Todos los outputs deben estar documentados con descripciones claras:

```hcl
output "certificate_arns" {
  description = "ARNs de los certificados creados"
  value       = { for k, v in aws_acm_certificate.certificate : k => v.arn }
}

output "dns_validation_records" {
  description = "Registros DNS necesarios para la validación (solo para certificados con validación DNS)"
  value = {
    for k, v in aws_acm_certificate.certificate : k => [
      for dvo in v.domain_validation_options : {
        domain = dvo.domain_name
        name   = dvo.resource_record_name
        type   = dvo.resource_record_type
        value  = dvo.resource_record_value
      } if v.validation_method == "DNS"
    ]
  }
}
```

### 8.5 CHANGELOG.md

El CHANGELOG.md debe seguir el formato [Keep a Changelog](https://keepachangelog.com/):

```markdown
# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2023-05-19

### Añadido
- Implementación inicial del módulo
- Característica A
- Característica B

### Cambiado
- Mejora en la funcionalidad X

### Corregido
- Bug en la funcionalidad Y
```

## 9. Seguridad y Cumplimiento

### 9.1 Análisis de Seguridad con Checkov

Cada módulo debe incluir un análisis de seguridad utilizando Checkov, una herramienta de análisis estático para infraestructura como código.

#### 9.1.1 Ejecución del Análisis

El análisis de seguridad debe ejecutarse sobre el plan de Terraform para capturar la configuración real que se aplicará:

```bash
# Generar el plan de Terraform
cd sample/
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Ejecutar Checkov sobre el plan
checkov -f tfplan.json --output json > ../security-reports/checkov/results.json
checkov -f tfplan.json --output cli > ../security-reports/checkov/results.txt
```

#### 9.1.2 Estructura de Directorios para Reportes de Seguridad

```
modulo-referencia/
├── security-reports/
│   ├── SECURITY-REPORT.md       # Informe detallado de seguridad
│   └── checkov/                 # Resultados de Checkov
│       ├── results.json         # Resultados en formato JSON
│       └── results.txt          # Resultados en formato texto
```

#### 9.1.3 Documentación en el README Principal

La sección de seguridad en el README principal debe seguir este formato:

```markdown
### Análisis de Seguridad

Este módulo ha sido analizado con [Checkov](https://www.checkov.io/) para detectar posibles vulnerabilidades y problemas de seguridad en la infraestructura como código.

#### Resultados del último escaneo

[![Checkov](https://img.shields.io/badge/Checkov-PASSED-success)](./security-reports/checkov/results.txt)

Puedes ver el reporte completo de seguridad en el [informe detallado](./security-reports/SECURITY-REPORT.md).

#### Resumen de hallazgos

| Severidad | Checkov | 
|-----------|---------|
| CRÍTICO   | 0       |
| ALTO      | 0       |
| MEDIO     | 0       |
| BAJO      | 0       |
| INFO      | 0       |
| **TOTAL** | 0       |

El análisis de seguridad no encontró problemas, lo que indica que el módulo sigue las mejores prácticas de seguridad.
```

#### 9.1.4 Informe Detallado de Seguridad

El archivo `SECURITY-REPORT.md` debe seguir esta estructura:

```markdown
# Informe de Seguridad: [Nombre del Módulo]

Este informe detalla los resultados del análisis de seguridad realizado en el módulo Terraform para [Nombre del Módulo]. El análisis fue ejecutado utilizando Checkov, una herramienta especializada en la detección de vulnerabilidades y problemas de seguridad en código de infraestructura.

## Resumen Ejecutivo

El módulo ha sido analizado con Checkov, una herramienta de análisis de políticas de seguridad para infraestructura como código que verifica cientos de políticas de seguridad predefinidas.

### Resultados Generales

| Severidad | Checkov | 
|-----------|---------|
| CRÍTICO   | X       |
| ALTO      | X       |
| MEDIO     | X       |
| BAJO      | X       |
| INFO      | X       |
| **TOTAL** | X       |

## Análisis Checkov

### Hallazgos Detallados

[Descripción de los hallazgos o indicación de que no se encontraron problemas]

**Resultados completos**: Los resultados completos del análisis Checkov están disponibles en formato texto [./checkov/results.txt](./checkov/results.txt) y en formato JSON [./checkov/results.json](./checkov/results.json).

## Mejores Prácticas Implementadas

[Lista de mejores prácticas de seguridad implementadas en el módulo]

## Recomendaciones

[Recomendaciones basadas en el análisis realizado]

## Conclusión

[Conclusión sobre la seguridad del módulo]
```

### 9.2 Mejores Prácticas de Seguridad

Implementa y documenta las mejores prácticas de seguridad específicas para cada tipo de recurso:

#### 9.2.1 Para ACM:
- Usar algoritmos de clave seguros (mínimo RSA_2048)
- Configurar renovación automática con `create_before_destroy = true`
- Preferir validación DNS sobre EMAIL por ser más segura

#### 9.2.2 Para EFS:
- Habilitar cifrado en reposo
- Configurar cifrado en tránsito
- Implementar políticas de acceso restrictivas

#### 9.2.3 Para ECS:
- Usar roles IAM con privilegios mínimos
- Configurar secretos de manera segura
- Implementar logging y monitoreo

### 9.3 Lista de Verificación de Cumplimiento

Incluye una lista de verificación de cumplimiento adaptada al tipo de recurso:

```markdown
## Lista de verificación de cumplimiento

- [x] Nomenclatura de recursos conforme al estándar
- [x] Etiquetas obligatorias aplicadas a todos los recursos
- [x] Validaciones para garantizar configuraciones correctas
- [x] Documentación sobre cómo validar certificados
- [x] Soporte para algoritmos de clave seguros
- [x] Renovación automática de certificados configurada
```

## 10. Pruebas y Validación

### 10.1 Pruebas Manuales

Documenta los pasos para probar manualmente el módulo:

```markdown
## Pruebas Manuales

1. Implementar el ejemplo del directorio `sample`
2. Verificar que los recursos se creen correctamente
3. Validar que los outputs contengan la información esperada
4. Probar los diferentes escenarios de uso
5. Verificar la integración con otros servicios
```

### 10.2 Pruebas Automatizadas (Opcional)

Si se implementan pruebas automatizadas, documenta cómo ejecutarlas:

```markdown
## Pruebas Automatizadas

Este módulo incluye pruebas automatizadas usando Terratest:

```bash
cd test
go test -v
```
```

## 11. Lista de Verificación para Módulos

Utiliza esta lista de verificación para asegurar que el módulo cumple con todos los estándares:

- [ ] Estructura de directorios correcta
- [ ] Convenciones de nomenclatura aplicadas
- [ ] Sistema de etiquetado implementado correctamente
- [ ] Uso de mapas de objetos para recursos
- [ ] Transformaciones con `locals` donde sea necesario
- [ ] Validación de variables implementada
- [ ] Configuración de proveedores con alias
- [ ] README.md principal completo y estructurado
- [ ] README.md del directorio sample completo
- [ ] Variables y outputs documentados
- [ ] CHANGELOG.md creado y actualizado
- [ ] Análisis de seguridad realizado
- [ ] Mejores prácticas de seguridad implementadas
- [ ] Lista de verificación de cumplimiento incluida
- [ ] Ejemplos de implementación incluidos
- [ ] Código formateado con `terraform fmt`
- [ ] Pruebas realizadas y documentadas

## 12. Versionado y Releases

### 12.1 Versionado Semántico

Utiliza [Versionado Semántico](https://semver.org/) para las versiones del módulo:

- **MAJOR**: Cambios incompatibles con versiones anteriores
- **MINOR**: Funcionalidad nueva compatible con versiones anteriores
- **PATCH**: Correcciones de errores compatibles con versiones anteriores

### 12.2 Etiquetas de Git

Etiqueta cada versión en Git:

```bash
git tag -a v1.0.0 -m "Versión inicial estable"
git push origin v1.0.0
```

### 12.3 Referencias en Módulos

Recomienda a los usuarios referenciar versiones específicas:

```hcl
module "acm" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-acm-terraform.git?ref=v1.0.0"
  # Resto de la configuración...
}
```

## Conclusión

Siguiendo estas reglas, podrás crear módulos de referencia Terraform que sean seguros, mantenibles, bien documentados y fáciles de usar por otros miembros del equipo.

> "Este módulo ha sido desarrollado siguiendo los estándares de Pragma CloudOps, garantizando una implementación segura, escalable y optimizada que cumple con todas las políticas de la organización. Pragma CloudOps recomienda revisar este código con su equipo de infraestructura antes de implementarlo en producción."
