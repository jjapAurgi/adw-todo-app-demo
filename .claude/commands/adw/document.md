---
description: Genera o actualiza documentacion basada en los cambios realizados
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Edit
  - Write
---

# Documentar Feature

Genera documentacion concisa en markdown para los cambios implementados, analizando el diff contra main y la especificacion original del plan. Crea documentacion en el directorio `app_docs/`.

## Variables

adw_id: $1
spec_path: $2 si se proporciona, de lo contrario dejalo en blanco
project_dir: $3 (opcional) - Directorio raiz del proyecto. Si se proporciona, usa esta ruta como base para todas las operaciones de ficheros (Write, Edit, Read). Si no se proporciona, usa el directorio de trabajo actual.

## Instrucciones

### 0. Resolver Directorio Base
- Si `project_dir` esta proporcionado, todas las rutas absolutas para operaciones de ficheros (Write, Edit, Read) deben construirse con `project_dir` como prefijo. Ejemplo: `{project_dir}/app_docs/feature.md`
- Si `project_dir` no esta proporcionado, usa el directorio de trabajo actual como base

### 1. Analizar Cambios
- Ejecuta `git diff origin/main --stat` para ver ficheros cambiados y lineas modificadas
- Ejecuta `git diff origin/main --name-only` para obtener la lista de ficheros cambiados
- Para cambios significativos (>50 lineas), ejecuta `git diff origin/main <file>` en ficheros especificos para entender los detalles de implementacion

### 2. Leer Especificacion (si se proporciona)
- Si `spec_path` esta proporcionado, lee el fichero de especificacion para entender:
  - Requisitos y objetivos originales
  - Funcionalidad esperada
  - Criterios de aceptacion
- Usa esto para enmarcar la documentacion alrededor de lo que se solicito vs lo que se construyo

### 3. Generar Documentacion
- Crea el directorio `app_docs/` si no existe
- Crea un nuevo fichero de documentacion en `app_docs/`
- Formato del nombre de fichero: `feature-{adw_id}-{nombre-descriptivo}.md`
  - Reemplaza `{nombre-descriptivo}` con un nombre corto del feature (ej: "user-auth", "data-export", "search-ui")
- Sigue el Formato de Documentacion de abajo
- Centrate en:
  - Que se construyo (basado en git diff)
  - Como funciona (implementacion tecnica)
  - Como usarlo (perspectiva del usuario)
  - Cualquier configuracion o setup necesario

### 4. Actualizar Documentacion Condicional
- Despues de crear el fichero de documentacion, comprueba si existe `app_docs/conditional_docs.md`
- Si no existe, crealo con una cabecera explicativa
- Anade una entrada para el nuevo fichero de documentacion con condiciones apropiadas
- La entrada debe ayudar a futuros desarrolladores a saber cuando leer esta documentacion
- Formatea la entrada siguiendo el patron existente en el fichero

### 5. Salida Final
- Cuando termines de escribir la documentacion y actualizar conditional_docs.md, devuelve exclusivamente la ruta al fichero de documentacion creado y nada mas

## Formato de Documentacion

```md
# <Titulo del Feature>

**ADW ID:** <adw_id>
**Fecha:** <fecha actual>
**Especificacion:** <spec_path o "N/A">

## Overview

<2-3 frases resumiendo que se construyo y por que>

## Que se Construyo

<Lista de los principales componentes/features implementados basado en el analisis del git diff>

- <Componente/feature 1>
- <Componente/feature 2>
- <etc>

## Implementacion Tecnica

### Ficheros Modificados

<Lista de ficheros clave cambiados con descripcion breve de los cambios>

- `<file_path>`: <que se cambio/anadio>
- `<file_path>`: <que se cambio/anadio>

### Cambios Clave

<Describe los cambios tecnicos mas importantes en 3-5 puntos>

## Como Usar

<Instrucciones paso a paso para usar la nueva funcionalidad>

1. <Paso 1>
2. <Paso 2>
3. <etc>

## Configuracion

<Opciones de configuracion, variables de entorno o settings>

## Testing

<Descripcion breve de como testear el feature>

## Notas

<Contexto adicional, limitaciones o consideraciones futuras>
```

## Formato de Entrada en Conditional Docs

Despues de crear la documentacion, anade esta entrada a `app_docs/conditional_docs.md`:

```md
- app_docs/<tu_fichero_de_documentacion>.md
  - Condiciones:
    - Cuando se trabaje con <area del feature>
    - Cuando se implemente <funcionalidad relacionada>
    - Cuando se resuelvan problemas de <issues especificas>
```

## Reporte

- IMPORTANTE: Devuelve exclusivamente la ruta al fichero de documentacion creado y nada mas.
