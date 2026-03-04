# Feature: Fecha Límite Opcional en Tareas (due_date)

**ADW ID:** 25302f69
**Fecha:** 2026-03-04
**Especificacion:** .issues/1/plan.md

## Overview

Se añadió un campo de fecha límite (`due_date`) opcional a las tareas de la aplicación Todo List. Las tareas pueden tener una fecha de vencimiento que se muestra con indicadores visuales de color según su proximidad: rojo para tareas vencidas y naranja para tareas que vencen pronto. Las tareas completadas no muestran indicadores de urgencia.

## Que se Construyo

- Campo `due_date` (tipo `date`, nullable) en la tabla `tasks` de la base de datos
- Validación en el modelo: no se permiten fechas pasadas al crear una tarea (permite null y edición de tareas existentes)
- Input de fecha en el formulario de creación de tareas (`TaskForm`)
- Indicadores visuales de color en `TaskItem` según el estado de la fecha (vencida/próxima/normal)
- Soporte en la API REST para enviar y recibir `due_date`
- Suite completa de tests unitarios e integración para backend y frontend

## Implementacion Tecnica

### Ficheros Modificados

- `backend/db/migrate/20260304144557_add_due_date_to_tasks.rb`: Migración para añadir columna `due_date date` nullable a la tabla `tasks`
- `backend/db/schema.rb`: Columna `due_date` añadida al schema de la tabla `tasks`
- `backend/app/models/task.rb`: Validación de `due_date` (no fechas pasadas en creación, permite nil)
- `backend/app/controllers/api/tasks_controller.rb`: `:due_date` añadido a los strong parameters
- `backend/test/fixtures/tasks.yml`: Fixture actualizado con `due_date` (3 días desde ahora)
- `backend/test/models/task_test.rb`: Tests unitarios de validación de `due_date`
- `backend/test/controllers/api/tasks_controller_test.rb`: Tests de integración CRUD con `due_date`
- `frontend/src/services/api.js`: `createTask` acepta y envía `dueDate` como `due_date`
- `frontend/src/components/TaskForm.jsx`: Estado `dueDate` y input `type="date"` añadidos
- `frontend/src/App.jsx`: `handleCreateTask` pasa `dueDate` al servicio API
- `frontend/src/components/TaskItem.jsx`: Lógica de estado de fecha y renderizado con estilos dinámicos
- `frontend/src/index.css`: Estilos `.task-date-input`, `.due-date`, `.due-date--overdue`, `.due-date--soon`
- `frontend/src/__tests__/TaskForm.test.jsx`: Tests del formulario con fecha
- `frontend/src/__tests__/TaskItem.test.jsx`: Tests de indicadores visuales

### Cambios Clave

1. **Migración y Schema**: Columna `due_date date` nullable añadida a `tasks`; el campo es completamente opcional.
2. **Validación de modelo**: `validates :due_date, comparison: { greater_than_or_equal_to: Date.today }, allow_nil: true, on: :create` — solo rechaza fechas pasadas al crear; permite actualizar tareas existentes con cualquier fecha.
3. **Lógica de estado en TaskItem**: Función `getDueDateStatus(dueDate, completed)` que calcula `'overdue'` (fecha pasada), `'soon'` (≤1 día restante) o `null`; retorna `null` para tareas completadas o sin fecha.
4. **Formato localizado**: Fecha formateada con `toLocaleDateString('es-ES')` (ej: "25 dic 2026").
5. **CSS adaptativo**: Clases `.due-date--overdue` (rojo, negrita) y `.due-date--soon` (naranja, negrita) aplicadas dinámicamente; tareas completadas nunca muestran indicadores de urgencia.

## Como Usar

1. Abre la aplicación Todo List en el navegador.
2. En el formulario de creación de tareas, introduce el título de la tarea.
3. Opcionalmente, selecciona una fecha límite usando el campo de fecha (debe ser hoy o una fecha futura).
4. Haz clic en "Añadir" para crear la tarea.
5. La tarea aparece en la lista con la fecha formateada:
   - Sin color especial si la fecha está en el futuro (más de 1 día).
   - **Naranja** si vence hoy o mañana.
   - **Rojo** si ya venció y la tarea no está completada.
6. Al marcar la tarea como completada, los indicadores de color desaparecen.

## Configuracion

No se requiere configuración adicional. El campo es nullable en la base de datos y opcional en el formulario.

- La validación de fecha pasada aplica únicamente en la creación (`on: :create`).
- El formateo de fecha usa el locale `es-ES` para consistencia con la UI en español.

## Testing

**Backend:**
```bash
cd backend && bin/rails test
```
- `task_test.rb`: Valida nil, fecha futura válida, fecha pasada inválida en creación.
- `tasks_controller_test.rb`: Crear con fecha, crear sin fecha, actualizar fecha, eliminar fecha (set null).

**Frontend:**
```bash
cd frontend && npm test -- --run
```
- `TaskForm.test.jsx`: Renderiza input de fecha, envío con/sin fecha, limpieza de campos.
- `TaskItem.test.jsx`: Muestra fecha formateada, indicadores `overdue`/`soon`, ausencia de indicadores en tareas completadas.

## Notas

- La validación de fecha pasada solo aplica en `on: :create`, permitiendo que tareas existentes con fechas vencidas puedan seguir siendo editadas sin errores.
- Los indicadores visuales se desactivan automáticamente en tareas completadas para evitar ruido visual innecesario.
- No se requieren gemas ni paquetes npm adicionales.
- El campo `due_date` es compatible con el flujo de actualización (PATCH): puede modificarse o eliminarse (set a null) en cualquier momento.
