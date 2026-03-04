# Chore: setup_worktree — fase de entorno en full_pipeline

## Descripción del Chore

Añadir una fase `setup_worktree` al flujo `full_pipeline` que crea un git worktree
aislado en `trees/<branch_name>/` por cada issue. El entorno incluye:

- **Infra aislada**: contenedor postgres propio por worktree vía `COMPOSE_PROJECT_NAME` +
  `POSTGRES_PORT` deterministas
- **Backend** con `PORT` determinista
- **Frontend** con `VITE_PORT` determinista
- **`.env.local`** en la raíz del worktree con todos los puertos y la referencia al `.env` raíz
- **GitHub label** `adw/setting_up` que refleja el estado

### Principio de composabilidad

**Una tarea = un comando Claude Code + un actor Ruby.** No hay actores monolíticos.
Los comandos son la implementación real (ejecutados por Claude); los actores son la
capa de orquestación de pipeline (tracker, error handling, logging). Ambos son
reutilizables de forma independiente.

La fase de setup se compone de tres tareas atómicas orquestadas por un workflow:

```
CreateWorktree    →  /env:worktree:create     (git worktree add)
ConfigureWorktree →  /env:worktree:configure  (genera .env.local con todos los puertos)
StartWorktreeEnv  →  /env:worktree:start      (infra + setup + backend + frontend)
```

Para teardown (cuando la issue se cierra):

```
DestroyWorktree   →  /env:worktree:destroy    (para servicios + infra + elimina worktree)
```

---

## Puertos deterministas

Dado `branch_name`, el algoritmo produce siempre los mismos puertos:

```
OFFSET = SHA256(branch_name)[0..7].to_i(16) % 900   # rango 0–899

POSTGRES_PORT  = 5400 + OFFSET   # 5400–6299
BACKEND_PORT   = 8000 + OFFSET   # 8000–8899
FRONTEND_PORT  = 9000 + OFFSET   # 9000–9899
```

**Ruby**: `Digest::SHA256.hexdigest(name)[0..7].to_i(16) % 900`

**Bash**: `$((16#$(echo -n "$NAME" | openssl dgst -sha256 | awk '{print $NF}' | head -c 8) % 900))`

Ambas implementaciones son equivalentes y deben mantenerse sincronizadas.

---

## Archivos Relevantes

### Ficheros existentes a modificar

- **`.gitignore`** — añadir `trees/`
- **`adws/lib/adw/tracker.rb`** — estado `setting_up`, campos `worktree_path`, `backend_port`,
  `frontend_port`, `postgres_port`, `compose_project`
- **`adws/lib/adw/workflows/full_pipeline.rb`** — expandir `PlanBuild` en actores individuales
  e insertar `Adw::Workflows::SetupWorktree` entre `CreateBranch` y `BuildPlan`
- **`adws/lib/adw.rb`** — añadir require explícito de `setup_worktree` workflow antes de `full_pipeline`
- **`adws/bin/trigger_cron`** — añadir `cleanup_stale_worktrees` para limpiar worktrees de
  issues cerradas
- **`backend/docker-compose.yml`** — ya soporta `${POSTGRES_PORT:-5432}:5432` ✓ — sin cambios

### Ficheros nuevos a crear

**Actores** (`adws/lib/adw/actors/`):
- `create_worktree.rb` — llama a `/env:worktree:create`; falla si el worktree ya existe
- `configure_worktree.rb` — llama a `/env:worktree:configure`; persiste puertos en tracker
- `start_worktree_env.rb` — llama a `/env:worktree:start`; no-bloqueante en fallo
- `destroy_worktree.rb` — llama a `/env:worktree:destroy`; limpia campos del tracker

**Workflow** (`adws/lib/adw/workflows/`):
- `setup_worktree.rb` — play de `CreateWorktree → ConfigureWorktree → StartWorktreeEnv`

**Comandos** (`.claude/commands/env/worktree/`):
- `create.md` — `git worktree add trees/{branch} {branch}` desde la raíz
- `configure.md` — genera `.env.local` con todos los puertos; output en JSON
- `start.md` — infra aislada + `db:prepare` + backend + frontend
- `destroy.md` — para servicios + infra del worktree + elimina worktree

**Script binario**:
- `adws/bin/adw_teardown_worktree` — invocado por el cron; carga tracker y llama a `DestroyWorktree`

**Tests**:
- `adws/test/lib/adw/actors/create_worktree_test.rb`
- `adws/test/lib/adw/actors/configure_worktree_test.rb`
- `adws/test/lib/adw/actors/start_worktree_env_test.rb`

---

## Tareas Paso a Paso

IMPORTANTE: Ejecuta cada paso en orden, de arriba a abajo.

### Paso 1: Añadir `trees/` al `.gitignore`

- Abrir `.gitignore` y añadir la entrada `trees/` en la sección ADW (junto a `.issues/` y `adws/log/`)

### Paso 2: Extender `tracker.rb` con estado `setting_up` y campos de worktree

- En `STATUS_EMOJIS`: añadir `"setting_up" => "🌲"` después de `"classifying"` y antes de `"planning"` (refleja el orden real del flujo)
- En `LABEL_COLORS`: añadir `"adw/setting_up" => "C3E6CB"` (verde claro)
- En `render_comment`: añadir bloque condicional si el tracker tiene worktree:
  ```ruby
  if tracker[:worktree_path]
    lines << "| **Worktree** | `#{File.basename(tracker[:worktree_path])}` |"
    lines << "| **Backend** | http://localhost:#{tracker[:backend_port]} |"
    lines << "| **Frontend** | http://localhost:#{tracker[:frontend_port]} |"
    lines << "| **Postgres** | localhost:#{tracker[:postgres_port]} (#{tracker[:compose_project]}) |"
  end
  ```
- En `save`: añadir al hash `data`:
  ```ruby
  "worktree_path"   => tracker[:worktree_path],
  "backend_port"    => tracker[:backend_port],
  "frontend_port"   => tracker[:frontend_port],
  "postgres_port"   => tracker[:postgres_port],
  "compose_project" => tracker[:compose_project],
  ```
- En `load`: añadir al hash resultante:
  ```ruby
  worktree_path:   data["worktree_path"],
  backend_port:    data["backend_port"],
  frontend_port:   data["frontend_port"],
  postgres_port:   data["postgres_port"],
  compose_project: data["compose_project"],
  ```

### Paso 3: Crear `.claude/commands/env/worktree/create.md`

Tarea: únicamente crear el git worktree en `trees/{BRANCH_NAME}`.

```markdown
---
description: Create a git worktree in trees/ for the given branch name
allowed-tools: Bash
---

# Create Git Worktree

## Variables

BRANCH_NAME: $1 — Nombre de la rama (ej: feat-42-abc12345-add-login)
TREES_DIR: trees
WORKTREE_PATH: {TREES_DIR}/{BRANCH_NAME}

## Instrucciones

- Ejecutar desde la raíz del proyecto
- Si el worktree ya existe, informar y salir sin error

## Workflow

1. Verificar que la carpeta `{TREES_DIR}/` existe; crearla si no (`mkdir -p trees`)
2. Comprobar si ya existe un worktree en `{WORKTREE_PATH}`:
   `git worktree list | grep {WORKTREE_PATH}`
   Si existe, informar al usuario y salir
3. Crear el worktree:
   `git worktree add {WORKTREE_PATH} {BRANCH_NAME}`
4. Reportar exclusivamente la ruta absoluta del worktree creado (sin texto adicional)
```

### Paso 4: Crear `.claude/commands/env/worktree/configure.md`

Tarea: calcular puertos deterministas y generar `.env.local` en el worktree.
El comando reporta JSON para que el actor persista los valores en el tracker.

```markdown
---
description: Generate .env.local with deterministic ports for a worktree
allowed-tools: Bash
---

# Configure Worktree Environment

## Variables

BRANCH_NAME: $1 — Nombre de la rama
WORKTREE_PATH: $2 — Ruta absoluta al worktree

## Algoritmo de puertos deterministas

Dado BRANCH_NAME, los puertos son SIEMPRE los mismos:

```bash
HASH=$(echo -n "$BRANCH_NAME" | openssl dgst -sha256 | awk '{print $NF}' | head -c 8)
OFFSET=$((16#$HASH % 900))
POSTGRES_PORT=$((5400 + OFFSET))
BACKEND_PORT=$((8000 + OFFSET))
FRONTEND_PORT=$((9000 + OFFSET))
COMPOSE_PROJECT="adw-$(echo "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | cut -c1-63)"
```

## Workflow

1. Calcular los cinco valores usando el algoritmo de arriba
2. Crear `{WORKTREE_PATH}/.env.local`:
   ```
   # Worktree: {BRANCH_NAME}
   # Generado automáticamente por ADW — NO EDITAR
   # Sobreescribe variables de ../../.env cuando se carga via env:worktree:start
   COMPOSE_PROJECT_NAME={COMPOSE_PROJECT}
   POSTGRES_PORT={POSTGRES_PORT}
   DATABASE_URL=postgresql://postgres:password@localhost:{POSTGRES_PORT}/app_development
   PORT={BACKEND_PORT}
   VITE_PORT={FRONTEND_PORT}
   VITE_API_BASE_URL=http://localhost:{BACKEND_PORT}
   ```
3. Reportar EXCLUSIVAMENTE el siguiente JSON (sin texto adicional):
   `{"postgres_port": {POSTGRES_PORT}, "backend_port": {BACKEND_PORT}, "frontend_port": {FRONTEND_PORT}, "compose_project": "{COMPOSE_PROJECT}"}`
```

### Paso 5: Crear `.claude/commands/env/worktree/start.md`

Tarea: arrancar infra aislada + preparar BD + backend + frontend en el worktree.

```markdown
---
description: Start all services (infra, backend, frontend) for a specific worktree
allowed-tools: Bash
---

# Start Worktree Services

## Variables

WORKTREE_PATH: $1 — Ruta absoluta al worktree

## Instrucciones

- Leer `.env.local` antes de ejecutar cualquier comando para tener los puertos correctos
- La infra usa `COMPOSE_PROJECT_NAME` + `POSTGRES_PORT` del `.env.local`
- Usar `run_in_background: true` para backend y frontend
- Si un puerto ya está en uso, informar pero no fallar

## Workflow

1. Leer y exportar todas las variables de `{WORKTREE_PATH}/.env.local`

2. Arrancar infra aislada desde `{WORKTREE_PATH}/backend/`:
   `COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME POSTGRES_PORT=$POSTGRES_PORT docker compose up -d`
   Esperar a que postgres responda (reintentar pg_isready hasta 30s)

3. Preparar la base de datos desde `{WORKTREE_PATH}/backend/`:
   `DATABASE_URL=$DATABASE_URL bin/rails db:prepare`

4. Iniciar backend en background desde `{WORKTREE_PATH}/backend/`:
   `PORT=$PORT bin/dev`

5. Iniciar frontend en background desde `{WORKTREE_PATH}/frontend/`:
   `bin/dev -- --port $VITE_PORT`

6. Informar al usuario:
   - Backend: http://localhost:$PORT
   - Frontend: http://localhost:$VITE_PORT
   - Postgres: localhost:$POSTGRES_PORT ($COMPOSE_PROJECT_NAME)
```

### Paso 6: Crear `.claude/commands/env/worktree/destroy.md`

Tarea: parar servicios + infra + eliminar worktree.

```markdown
---
description: Stop all services and remove a git worktree
allowed-tools: Bash
---

# Destroy Worktree

## Variables

BRANCH_NAME: $1 — Nombre de la rama / directorio en trees/
WORKTREE_PATH: trees/{BRANCH_NAME}

## Workflow

1. Leer `{WORKTREE_PATH}/.env.local` para obtener COMPOSE_PROJECT_NAME

2. Parar el frontend:
   - PID file: `{WORKTREE_PATH}/frontend/tmp/pids/vite.pid`
   - Si existe: SIGTERM → esperar 5s → SIGKILL si sigue vivo → eliminar PID file

3. Parar el backend:
   - PID file: `{WORKTREE_PATH}/backend/tmp/pids/server.pid`
   - Si existe: SIGTERM → esperar 5s → SIGKILL si sigue vivo
   - Limpiar `{WORKTREE_PATH}/backend/tmp/sockets/` y PID file

4. Parar la infra del worktree desde `{WORKTREE_PATH}/backend/`:
   `COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME docker compose down -v`
   (el flag -v elimina el volumen de datos postgres de este worktree)

5. Eliminar el worktree:
   `git worktree remove {WORKTREE_PATH} --force`

6. Limpiar referencias huérfanas:
   `git worktree prune`

7. Confirmar al usuario que el worktree ha sido eliminado
```

### Paso 7: Crear `adws/lib/adw/actors/create_worktree.rb`

```ruby
# frozen_string_literal: true

require "open3"
require "fileutils"

module Adw
  module Actors
    class CreateWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :branch_name
      output :tracker
      output :worktree_path

      TREES_DIR = "trees"

      def call
        log_actor("Creating worktree for branch: #{branch_name}")

        path = File.join(Adw.project_root, TREES_DIR, branch_name)
        FileUtils.mkdir_p(File.join(Adw.project_root, TREES_DIR))

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_creator",
          slash_command: "/env:worktree:create",
          args: [branch_name],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "haiku"
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Worktree creation failed: #{response.output}")
        end

        self.worktree_path = path
        tracker[:worktree_path] = path
        logger.info("Worktree created: #{path}")
      end
    end
  end
end
```

### Paso 8: Crear `adws/lib/adw/actors/configure_worktree.rb`

```ruby
# frozen_string_literal: true

require "digest"
require "json"

module Adw
  module Actors
    class ConfigureWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :branch_name
      input :worktree_path
      output :tracker

      PORT_RANGES = { postgres: 5400, backend: 8000, frontend: 9000 }.freeze
      PORT_RANGE  = 900

      def call
        log_actor("Configuring worktree environment for: #{branch_name}")

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_configurator",
          slash_command: "/env:worktree:configure",
          args: [branch_name, worktree_path],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "haiku"
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Worktree configuration failed: #{response.output}")
        end

        ports = parse_ports(response.output)
        tracker[:backend_port]    = ports[:backend_port]
        tracker[:frontend_port]   = ports[:frontend_port]
        tracker[:postgres_port]   = ports[:postgres_port]
        tracker[:compose_project] = ports[:compose_project]
        Adw::Tracker.save(issue_number, tracker)

        logger.info("Configured — backend: #{ports[:backend_port]}, frontend: #{ports[:frontend_port]}, postgres: #{ports[:postgres_port]}")
      end

      private

      def parse_ports(output)
        data = JSON.parse(output.strip)
        {
          backend_port:    data["backend_port"],
          frontend_port:   data["frontend_port"],
          postgres_port:   data["postgres_port"],
          compose_project: data["compose_project"]
        }
      rescue JSON::ParserError
        logger.warn("[ConfigureWorktree] JSON parse failed — using local calculation")
        calculate_ports_locally
      end

      def calculate_ports_locally
        offset  = Digest::SHA256.hexdigest(branch_name)[0..7].to_i(16) % PORT_RANGE
        project = "adw-#{branch_name.downcase.gsub(/[^a-z0-9-]/, "-")[0..62]}"
        {
          postgres_port:   PORT_RANGES[:postgres]  + offset,
          backend_port:    PORT_RANGES[:backend]   + offset,
          frontend_port:   PORT_RANGES[:frontend]  + offset,
          compose_project: project
        }
      end
    end
  end
end
```

### Paso 9: Crear `adws/lib/adw/actors/start_worktree_env.rb`

```ruby
# frozen_string_literal: true

module Adw
  module Actors
    class StartWorktreeEnv < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :worktree_path
      output :tracker

      def call
        log_actor("Starting worktree environment: #{worktree_path}")
        Adw::Tracker.update(tracker, issue_number, "setting_up", logger)

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_starter",
          slash_command: "/env:worktree:start",
          args: [worktree_path],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "sonnet"
        )

        response = Adw::Agent.execute_template(request)
        unless response.success
          logger.warn("[StartWorktreeEnv] Services failed to start (non-blocking): #{response.output}")
        end
      rescue => e
        logger.warn("[StartWorktreeEnv] Exception starting services (non-blocking): #{e.message}")
      end
    end
  end
end
```

### Paso 10: Crear `adws/lib/adw/actors/destroy_worktree.rb`

```ruby
# frozen_string_literal: true

module Adw
  module Actors
    class DestroyWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      output :tracker

      def call
        worktree_path = tracker[:worktree_path]
        branch_name   = worktree_path ? File.basename(worktree_path) : nil

        unless worktree_path && Dir.exist?(worktree_path)
          logger.info("[DestroyWorktree] No active worktree found, skipping")
          return
        end

        log_actor("Destroying worktree: #{worktree_path}")

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_destroyer",
          slash_command: "/env:worktree:destroy",
          args: [branch_name],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "sonnet"
        )

        response = Adw::Agent.execute_template(request)
        unless response.success
          logger.warn("[DestroyWorktree] Destroy had issues (non-blocking): #{response.output}")
        end

        tracker.delete(:worktree_path)
        tracker.delete(:backend_port)
        tracker.delete(:frontend_port)
        tracker.delete(:postgres_port)
        tracker.delete(:compose_project)
        Adw::Tracker.save(issue_number, tracker)

        logger.info("Worktree destroyed: #{worktree_path}")
      end
    end
  end
end
```

### Paso 11: Crear `adws/lib/adw/workflows/setup_worktree.rb`

```ruby
# frozen_string_literal: true

module Adw
  module Workflows
    class SetupWorktree < Actor
      input :issue_number
      input :adw_id
      input :logger
      input :tracker
      input :branch_name
      output :tracker
      output :worktree_path

      play Adw::Actors::CreateWorktree,
           Adw::Actors::ConfigureWorktree,
           Adw::Actors::StartWorktreeEnv
    end
  end
end
```

### Paso 12: Actualizar `adws/lib/adw.rb` — load order

Añadir require explícito de `setup_worktree` workflow **antes** de que el `Dir[...].sort.each`
cargue `full_pipeline` (que referencia `Adw::Workflows::SetupWorktree`):

```ruby
# Load workflows (load order matters for compositions)
require_relative "adw/workflows/plan_build"
require_relative "adw/workflows/setup_worktree"   # ← añadir aquí
Dir[File.join(__dir__, "adw/workflows/**/*.rb")].sort.each { |f| require f }
```

### Paso 13: Modificar `adws/lib/adw/workflows/full_pipeline.rb`

```ruby
# frozen_string_literal: true

module Adw
  module Workflows
    class FullPipeline < Actor
      input :issue_number
      input :adw_id
      input :logger

      play Adw::Actors::InitializeTracker,
           Adw::Actors::FetchIssue,
           Adw::Actors::ClassifyIssue,
           Adw::Actors::CreateBranch,
           Adw::Workflows::SetupWorktree,
           Adw::Actors::BuildPlan,
           Adw::Actors::PublishPlan,
           Adw::Actors::ImplementPlan,
           Adw::Actors::TestWithResolution,
           Adw::Actors::PublishTestResults,
           Adw::Actors::ReviewCode,
           Adw::Actors::ReviewIssue,
           Adw::Actors::GenerateDocs,
           Adw::Actors::CommitChanges,
           Adw::Actors::CreatePullRequest,
           Adw::Actors::MarkDone
    end
  end
end
```

`PlanBuild` sigue sin cambios — `adw_plan_build` y `adw_plan_build_test` no usan worktrees.

### Paso 14: Crear `adws/bin/adw_teardown_worktree`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true
#
# ADW Teardown Worktree
# Usage: adw_teardown_worktree <branch_name>
#
# Invocado por trigger_cron cuando la issue de un worktree está cerrada.
#

require "bundler/setup"
require_relative "../lib/adw"

if ARGV.length < 1
  puts "Usage: adw_teardown_worktree <branch_name>"
  exit 1
end

branch_name  = ARGV[0]
adw_id       = Adw::Utils.make_adw_id
# Branch format: type-ISSUE_NUM-adwid-name
issue_number = branch_name.split("-")[1].to_i

if issue_number == 0
  warn "ERROR: Cannot extract issue number from branch: #{branch_name}"
  exit 1
end

logger  = Adw::Utils.setup_logger(issue_number, adw_id, "adw_teardown_worktree")
tracker = Adw::Tracker.load(issue_number) || {}
tracker[:adw_id] ||= adw_id

if tracker[:worktree_path].nil?
  candidate = File.join(Adw.project_root, "trees", branch_name)
  tracker[:worktree_path] = candidate if Dir.exist?(candidate)
end

result = Adw::Actors::DestroyWorktree.result(
  issue_number: issue_number,
  adw_id: adw_id,
  logger: logger,
  tracker: tracker
)

unless result.success?
  logger.error("Teardown failed: #{result.error}")
  exit 1
end

logger.info("Teardown complete for #{branch_name}")
```

- Marcar como ejecutable: `chmod +x adws/bin/adw_teardown_worktree`

### Paso 15: Extender `adws/bin/trigger_cron` con limpieza de worktrees

Añadir dentro de `Adw::Pipelines::TriggerCron`:

```ruby
def trigger_worktree_teardown(branch_name)
  script_path = File.join(__dir__, "adw_teardown_worktree")
  puts "INFO: Triggering worktree teardown for branch: #{branch_name}"
  pid = Process.spawn(
    RbConfig.ruby, script_path, branch_name,
    out: $stdout, err: $stderr
  )
  Process.detach(pid)
  puts "INFO: Teardown spawned for #{branch_name} (PID: #{pid})"
  true
rescue => e
  warn "ERROR: Exception triggering teardown for #{branch_name}: #{e}"
  false
end

def cleanup_stale_worktrees(open_issue_numbers)
  trees_dir = File.join(Adw.project_root, "trees")
  return unless Dir.exist?(trees_dir)

  Dir.entries(trees_dir).reject { |e| e.start_with?(".") }.each do |branch_name|
    # Branch format: type-ISSUE_NUM-adwid-name
    parts = branch_name.split("-")
    next if parts.length < 2

    issue_num = parts[1].to_i
    next if issue_num == 0
    next if open_issue_numbers.include?(issue_num)

    puts "INFO: Issue ##{issue_num} closed — removing worktree: #{branch_name}"
    trigger_worktree_teardown(branch_name)
  end
end
```

En `check_and_process_issues`, al final del bloque `begin` (antes del log del tiempo de ciclo):

```ruby
cleanup_stale_worktrees(issues.map(&:number).to_set)
```

### Paso 16: Crear tests unitarios

Seguir el patrón del proyecto (`include TestFactories`, `build_logger`, `build_tracker`,
`Adw::Tracker.stubs(:update)`, `Adw::Agent.stubs(:execute_template)`).

**`adws/test/lib/adw/actors/create_worktree_test.rb`**:
- `test_creates_worktree_and_sets_outputs` — agent exitoso → `worktree_path` en output y tracker
- `test_fails_when_agent_fails` — agent falla → result no es success, mensaje incluye "Worktree creation failed"

**`adws/test/lib/adw/actors/configure_worktree_test.rb`**:
- `test_parses_port_json_and_updates_tracker` — agent devuelve JSON válido → tracker tiene los 4 campos
- `test_fallback_to_local_calculation_on_bad_json` — agent devuelve texto no-JSON → cálculo local, ports en rango
- `test_deterministic_ports` — mismos inputs → mismos outputs siempre

**`adws/test/lib/adw/actors/start_worktree_env_test.rb`**:
- `test_updates_tracker_to_setting_up` — verifica que `Tracker.update` se llama con `"setting_up"`
- `test_service_failure_is_non_blocking` — agent falla → result es success (no propaga error)

---

## Comandos de Validación

```bash
# 1. Carga de librería sin errores
cd adws && bundle exec ruby -e "require_relative 'lib/adw'; puts 'ADW loaded OK'"

# 2. Tests de los nuevos actores
cd adws && bundle exec ruby -Itest test/lib/adw/actors/create_worktree_test.rb
cd adws && bundle exec ruby -Itest test/lib/adw/actors/configure_worktree_test.rb
cd adws && bundle exec ruby -Itest test/lib/adw/actors/start_worktree_env_test.rb

# 3. Suite completa ADW (sin regresiones)
cd adws && bundle exec rake test

# 4. Sintaxis de los nuevos binarios
cd adws && bundle exec ruby -c bin/trigger_cron
cd adws && bundle exec ruby -c bin/adw_teardown_worktree

# 5. Tests de la app (sin regresiones)
cd backend && bin/rails test
cd frontend && npm test -- --run
```

---

## Notas

### Composabilidad: comando + actor

Cada comando Claude Code es reutilizable de forma independiente por el usuario.
El actor correspondiente añade: actualización de tracker, log estructurado, manejo
de errores con `fail!` y propagación al pipeline. `StartWorktreeEnv` es
intencionalmente **no-bloqueante**: un fallo al arrancar servicios no debe abortar
el pipeline.

### Aislamiento de infra por worktree

`COMPOSE_PROJECT_NAME` es el mecanismo nativo de Docker Compose para aislar proyectos:
contenedores y volúmenes completamente separados. `docker compose down -v` en `destroy`
elimina el volumen de datos postgres del worktree. El `docker-compose.yml` del proyecto
ya soporta `${POSTGRES_PORT:-5432}` — no requiere cambios.

### `.env.local` y herencia del `.env` raíz

El fichero `.env.local` sólo contiene overrides del worktree. El comando
`env:worktree:start` carga primero `../../.env` (base) y después `.env.local`
(precedencia). Así `DATABASE_URL`, `PORT`, `VITE_PORT` y `COMPOSE_PROJECT_NAME`
del worktree sobreescriben los valores del `.env` raíz.

### Load order en `adw.rb`

`setup_worktree.rb` workflow (S) se cargaría DESPUÉS de `full_pipeline.rb` (F) por
el orden alfabético del `Dir[...].sort.each`. Como `FullPipeline` referencia
`Adw::Workflows::SetupWorktree`, se necesita el require explícito antes del glob.

### Flujos no afectados

`PlanBuild`, `PlanBuildTest` y `Patch` no usan worktrees y no se modifican.
