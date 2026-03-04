---
description: Crea un plan de patch focalizado para resolver un issue especifico de revision
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Write
---

# Patch Plan

Crea un **plan de patch focalizado** para resolver un issue especifico basado en el `review_change_request`. Sigue las `Instrucciones` para crear un plan conciso que aborde el problema con cambios minimos y dirigidos.

## Variables

adw_id: $1
review_change_request: $2
issue_number: $3
spec_path: $4 si se proporciona, de lo contrario dejalo en blanco

## Instrucciones

- IMPORTANTE: Estas creando un plan de patch para resolver un issue especifico de revision. Mantén los cambios pequenos, focalizados y dirigidos.
- Lee el fichero de especificacion (spec) en `spec_path` si se proporciona para entender el contexto y los requisitos originales.
- IMPORTANTE: Usa el `review_change_request` para entender exactamente que necesita cambiarse y usalo como base para tu patch plan.
- Crea el patch plan en `.issues/{issue_number}/` con nombre: `patch-{n}-{nombre-descriptivo}.md`
  - `{n}` es el siguiente numero secuencial. Cuenta los ficheros `patch-*.md` existentes en `.issues/{issue_number}/` y usa count+1.
  - Reemplaza `{nombre-descriptivo}` con un nombre corto basado en el issue (ej: "fix-button-color", "add-validation", "correct-layout")
  - Crea el directorio `.issues/{issue_number}/` si no existe (`mkdir -p`).
- IMPORTANTE: Esto es un PATCH - mantén el alcance minimo. Solo corrige lo descrito en el `review_change_request` y nada mas.
- Ejecuta `git diff --stat`. Si hay cambios disponibles, usalos para entender que se ha hecho en el codebase y asi puedas detallar los cambios exactos en el patch plan.
- Piensa profundamente sobre la forma mas eficiente de implementar la solucion con cambios minimos de codigo.
- Basa la seccion `Validation` en los tests de `.claude/commands/adw/test.md: ## Secuencia de Ejecucion de Tests`.
- Reemplaza cada <placeholder> en el `Formato del Plan` con detalles especificos de implementacion.
- IMPORTANTE: Cuando termines de escribir el patch plan, devuelve exclusivamente la ruta al fichero creado y nada mas.

## Ficheros Relevantes

Centrate en los siguientes ficheros:
- `backend/app/**` - Contiene el codigo del servidor Rails API.
- `frontend/src/**` - Contiene el codigo del cliente React.
- `plans/` - Contiene planes existentes para referencia.

- Lee `app_docs/conditional_docs.md` para comprobar si tu tarea requiere documentacion adicional. Si tu tarea coincide con alguna de las condiciones listadas, referencia esos ficheros de documentacion para entender mejor el contexto al crear tu patch plan.

## Formato del Plan

```md
# Patch: <titulo conciso del patch>

## Metadata
adw_id: `{adw_id}`
review_change_request: `{review_change_request}`

## Issue Summary
**Plan original:** <spec_path o N/A>
**Problema:** <descripcion breve del issue basada en review_change_request>
**Solucion:** <descripcion breve del approach de solucion>

## Files to Modify
Usa estos ficheros para implementar el patch:

<lista solo los ficheros que necesitan cambios - se especifico y minimo>

## Implementation Steps
IMPORTANTE: Ejecutar cada paso en orden, de arriba a abajo.

<lista 2-5 pasos focalizados para implementar el patch. Cada paso debe ser una accion concreta.>

### Step 1: <accion especifica>
- <detalle de implementacion>
- <detalle de implementacion>

### Step 2: <accion especifica>
- <detalle de implementacion>
- <detalle de implementacion>

<continuar segun sea necesario, pero mantenerlo minimo>

## Validation
Ejecutar cada comando para validar que el patch esta completo sin regresiones.

<lista 1-5 comandos o comprobaciones especificas para verificar que el patch funciona>

## Patch Scope
**Lineas de codigo a cambiar:** <estimacion>
**Nivel de riesgo:** <low|medium|high>
**Testing requerido:** <descripcion breve>
```

## Reporte

- IMPORTANTE: Devuelve exclusivamente la ruta al fichero de patch plan creado y nada mas.
