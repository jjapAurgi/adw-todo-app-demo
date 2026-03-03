---
description: Revisa los cambios implementados verificando calidad tecnica y posibles problemas
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Revision Tecnica de Codigo

Revisa los cambios realizados en la rama actual comparandolos con la rama main, evaluando calidad de codigo y posibles problemas tecnicos.

## Variables

ISSUE: $1 - JSON de la issue de Github
PLAN_PATH: $2 - Ruta al fichero del plan de implementacion

## Instrucciones

- Analiza todos los cambios realizados en la rama actual respecto a main.
- Evalua los cambios segun los criterios de revision definidos abajo.
- Cada criterio debe evaluarse como PASS o FAIL con una justificacion breve.
- Si hay hallazgos criticos (seguridad, datos perdidos, logica rota), marca severity como "critical".
- Si hay hallazgos importantes pero no bloqueantes, marca severity como "warning".
- Si todo esta correcto, marca severity como "info".
- IMPORTANTE: Devuelve SOLO el JSON con los resultados de la revision.
  - IMPORTANTE: No incluyas texto adicional, explicaciones ni formato markdown.
  - Ejecutaremos JSON.parse() directamente sobre la salida, asi que asegurate de que sea JSON valido.

## Workflow

### Paso 1: Obtener contexto de cambios
- Ejecuta `git diff origin/main...HEAD` para ver todos los cambios.
- Ejecuta `git diff origin/main...HEAD --stat` para ver resumen de ficheros.
- Ejecuta `git log origin/main..HEAD --oneline` para ver commits.

### Paso 2: Leer el plan de implementacion
- Lee PLAN_PATH para entender que se esperaba implementar.
- Extrae los criterios de aceptacion y los requisitos del plan.

### Paso 3: Evaluar criterios de revision
Evalua cada uno de los siguientes criterios:

1. **code_quality**: El codigo sigue las convenciones del proyecto, es legible, y no tiene code smells evidentes (duplicacion excesiva, funciones demasiado largas, nombres poco descriptivos).
2. **unintended_changes**: No hay cambios en ficheros no relacionados con la issue. No hay ficheros de configuracion, dependencias o assets modificados sin justificacion.
3. **security**: No hay credenciales hardcodeadas, inyecciones SQL, XSS, o exposicion de datos sensibles en los cambios.
4. **error_handling**: Los cambios incluyen manejo de errores adecuado donde es necesario (validaciones, try/catch, respuestas de error).
5. **naming_conventions**: Nombres de variables, funciones, clases y ficheros siguen las convenciones del lenguaje y del proyecto.

## Reporte

- IMPORTANTE: Devuelve resultados exclusivamente como un objeto JSON basado en la seccion `Estructura de Salida`.

### Estructura de Salida

```json
{
  "overall_severity": "info | warning | critical",
  "summary": "string - resumen general de la revision",
  "checks": [
    {
      "name": "string - nombre del criterio",
      "result": "PASS | FAIL",
      "severity": "info | warning | critical",
      "details": "string - justificacion o hallazgos"
    }
  ],
  "action_required": "none | fix_and_rerun",
  "fix_suggestions": ["string - sugerencias de correccion si action_required es fix_and_rerun"]
}
```

### Ejemplo de Salida

```json
{
  "overall_severity": "warning",
  "summary": "La implementacion es de buena calidad tecnica. Se encontraron 2 hallazgos menores en naming conventions.",
  "checks": [
    {
      "name": "code_quality",
      "result": "PASS",
      "severity": "info",
      "details": "Codigo limpio y bien estructurado."
    },
    {
      "name": "unintended_changes",
      "result": "PASS",
      "severity": "info",
      "details": "Solo se modificaron ficheros relacionados con la issue."
    },
    {
      "name": "security",
      "result": "PASS",
      "severity": "info",
      "details": "No se encontraron problemas de seguridad."
    },
    {
      "name": "error_handling",
      "result": "PASS",
      "severity": "info",
      "details": "Manejo de errores adecuado en los endpoints modificados."
    },
    {
      "name": "naming_conventions",
      "result": "FAIL",
      "severity": "warning",
      "details": "La variable 'tmp' en tasks_controller.rb:45 deberia tener un nombre mas descriptivo."
    }
  ],
  "action_required": "none",
  "fix_suggestions": []
}
```
