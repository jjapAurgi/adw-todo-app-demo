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
