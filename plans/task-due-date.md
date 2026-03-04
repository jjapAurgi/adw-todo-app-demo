# Feature: Fecha límite opcional en tareas

## Descripción de la Funcionalidad
Añadir un campo de fecha límite (due date) opcional a las tareas. Los usuarios podrán establecer, modificar o eliminar una fecha de vencimiento al crear o editar una tarea. Las tareas con fecha límite vencida se mostrarán con un indicador visual para alertar al usuario.

## Historia de Usuario
Como usuario de la aplicación de tareas
Quiero poder asignar una fecha límite opcional a mis tareas
Para que pueda organizar mejor mi trabajo y saber qué tareas son urgentes

## Planteamiento del Problema
Actualmente las tareas solo tienen título y estado de completado. No hay forma de indicar cuándo debe completarse una tarea, lo que dificulta la priorización y planificación del trabajo.

## Propuesta de Solución
Añadir un campo `due_date` de tipo `date` (nullable) a la tabla `tasks`. En el frontend, incluir un input de tipo date en el formulario de creación y mostrar la fecha límite en cada tarea con indicadores visuales (vencida en rojo, próxima a vencer en naranja).

## Archivos Relevantes
Usa estos ficheros para implementar la funcionalidad:

- `backend/app/models/task.rb` — Modelo Task, añadir validación de due_date
- `backend/app/controllers/api/tasks_controller.rb` — Permitir due_date en task_params
- `backend/db/schema.rb` — Referencia del esquema actual
- `backend/test/models/task_test.rb` — Tests del modelo Task
- `backend/test/controllers/api/tasks_controller_test.rb` — Tests del controlador
- `backend/test/fixtures/tasks.yml` — Fixtures de test
- `frontend/src/App.jsx` — Componente raíz, pasar due_date en handlers
- `frontend/src/services/api.js` — Función createTask necesita aceptar due_date
- `frontend/src/components/TaskForm.jsx` — Formulario de creación, añadir input date
- `frontend/src/components/TaskItem.jsx` — Mostrar fecha límite e indicador visual
- `frontend/src/index.css` — Estilos para indicadores de fecha
- `frontend/src/__tests__/TaskForm.test.jsx` — Tests del formulario
- `frontend/src/__tests__/TaskItem.test.jsx` — Tests del item
- `frontend/src/__tests__/App.test.jsx` — Tests de integración del App

### Ficheros Nuevos
- `backend/db/migrate/XXXXXX_add_due_date_to_tasks.rb` — Migración para añadir columna due_date

## Plan de Implementación
### Fase 1: Fundamentos
Crear la migración de base de datos para añadir el campo `due_date` (tipo `date`, nullable) a la tabla `tasks`. Actualizar el modelo y el controlador para aceptar y exponer el nuevo campo.

### Fase 2: Implementación Principal
Modificar el frontend para incluir un date picker en el formulario de creación, pasar `due_date` a través del servicio API, y mostrar la fecha en cada tarea con indicadores visuales de estado (vencida, próxima, normal).

### Fase 3: Integración
Asegurar que todas las operaciones existentes (crear, actualizar, reordenar, eliminar) funcionan correctamente con el nuevo campo. Actualizar tests en backend y frontend.

## Tareas Paso a Paso
IMPORTANTE: Ejecuta cada paso en orden, de arriba a abajo.

### Paso 1: Crear migración de base de datos
- Generar migración: `cd backend && bin/rails generate migration AddDueDateToTasks due_date:date`
- Ejecutar migración: `cd backend && bin/rails db:migrate`
- Verificar que `db/schema.rb` incluye la columna `due_date`

### Paso 2: Actualizar modelo Task
- En `backend/app/models/task.rb`, añadir validación opcional de `due_date`:
  - `validates :due_date, comparison: { greater_than_or_equal_to: -> { Date.today } }, allow_nil: true, on: :create`
- Ejecutar `cd backend && bin/rails annotaterb models` para actualizar anotaciones del modelo

### Paso 3: Actualizar controlador
- En `backend/app/controllers/api/tasks_controller.rb`, añadir `:due_date` a `task_params`

### Paso 4: Actualizar fixtures y tests del backend
- Añadir `due_date` a algunas fixtures en `backend/test/fixtures/tasks.yml` (al menos una con fecha futura y una sin fecha)
- En `backend/test/models/task_test.rb`:
  - Test: tarea válida con due_date nil
  - Test: tarea válida con due_date futura
  - Test: tarea inválida con due_date pasada al crear
- En `backend/test/controllers/api/tasks_controller_test.rb`:
  - Test: crear tarea con due_date
  - Test: crear tarea sin due_date
  - Test: actualizar due_date de una tarea existente
  - Test: eliminar due_date (poner a null)
- Ejecutar tests: `cd backend && bin/rails test`

### Paso 5: Actualizar servicio API del frontend
- En `frontend/src/services/api.js`, modificar `createTask` para aceptar un objeto con `title` y `due_date` opcionales (o parámetros separados)
- Asegurar que `updateTask` ya soporta enviar `due_date`

### Paso 6: Actualizar TaskForm
- En `frontend/src/components/TaskForm.jsx`:
  - Añadir estado `dueDate` (inicialmente vacío)
  - Añadir input `<input type="date">` al lado del input de título
  - Pasar `dueDate` al handler `onCreateTask`
  - Limpiar `dueDate` tras envío exitoso

### Paso 7: Actualizar App.jsx
- En `frontend/src/App.jsx`:
  - Modificar `handleCreateTask` para recibir y enviar `due_date` al API
  - Asegurar que la respuesta del API con `due_date` se refleja en el estado

### Paso 8: Actualizar TaskItem
- En `frontend/src/components/TaskItem.jsx`:
  - Mostrar la fecha límite junto al título si existe
  - Añadir indicador visual:
    - Rojo si la fecha ya pasó y la tarea no está completada
    - Naranja si la fecha es hoy o mañana y la tarea no está completada
    - Gris/normal en otros casos o si la tarea está completada
  - Formatear la fecha de forma legible (ej: "4 mar 2026")

### Paso 9: Actualizar estilos CSS
- En `frontend/src/index.css`:
  - Estilos para `.due-date` (tamaño, color base gris)
  - Estilos para `.due-date--overdue` (color rojo `#e74c3c`)
  - Estilos para `.due-date--soon` (color naranja `#f39c12`)
  - Estilos para el input date en el formulario

### Paso 10: Actualizar tests del frontend
- En `frontend/src/__tests__/TaskForm.test.jsx`:
  - Test: renderiza input de fecha
  - Test: envía tarea con fecha límite
  - Test: envía tarea sin fecha límite
  - Test: limpia fecha tras envío
- En `frontend/src/__tests__/TaskItem.test.jsx`:
  - Test: muestra fecha límite cuando existe
  - Test: no muestra fecha cuando no existe
  - Test: muestra indicador rojo cuando está vencida
  - Test: muestra indicador naranja cuando es próxima
- En `frontend/src/__tests__/App.test.jsx`:
  - Test: crear tarea con fecha límite

### Paso 11: Validación final
- Ejecutar los `Comandos de Validación` para confirmar que todo funciona sin regresiones

## Estrategia de Testing
### Tests Unitarios
- Modelo Task: validaciones de due_date (nil permitido, fecha futura en creación, fecha pasada rechazada en creación)
- Componente TaskForm: renderizado del input date, envío con y sin fecha
- Componente TaskItem: renderizado condicional de fecha, clases CSS de indicadores

### Tests de Integración
- Controlador: CRUD completo con due_date (crear con fecha, actualizar fecha, eliminar fecha)
- App.jsx: flujo completo de crear tarea con fecha límite

### Casos Límite
- Crear tarea sin fecha límite (debe funcionar como antes)
- Crear tarea con fecha de hoy (debe ser válida)
- Actualizar tarea existente para añadir fecha límite
- Actualizar tarea existente para quitar fecha límite (poner a null)
- Tarea con fecha vencida que se marca como completada (indicador visual cambia)
- Tarea con fecha vencida que se actualiza (validación de fecha pasada no aplica en update, solo en create)

## Criterios de Aceptación
- El campo due_date es opcional: las tareas pueden crearse sin fecha límite
- El formulario de creación incluye un date picker opcional
- Las tareas muestran su fecha límite cuando existe
- Las tareas vencidas no completadas muestran indicador rojo
- Las tareas próximas a vencer (hoy/mañana) no completadas muestran indicador naranja
- Las tareas completadas no muestran indicadores de urgencia independientemente de la fecha
- Todas las operaciones existentes (crear, completar, reordenar, eliminar) siguen funcionando
- Los tests de backend y frontend pasan sin errores

## Comandos de Validación
Ejecuta cada comando para validar que la funcionalidad funciona correctamente sin regresiones.

- `cd /home/work/anjana_master/entaina/backend && bin/rails test` - Ejecuta los tests del backend para validar que la funcionalidad funciona sin regresiones
- `cd /home/work/anjana_master/entaina/frontend && npm test` - Ejecuta los tests del frontend para validar que la funcionalidad funciona sin regresiones

## Notas
- La validación de fecha futura solo aplica en creación (`on: :create`), no en actualización, para permitir que tareas con fechas que ya pasaron puedan editarse sin problemas
- Se usa `type="date"` nativo del navegador para el date picker, sin dependencias adicionales
- El formato de visualización de fecha se hará con `toLocaleDateString('es-ES')` para consistencia con el idioma
- No se requieren nuevas gemas ni paquetes npm
