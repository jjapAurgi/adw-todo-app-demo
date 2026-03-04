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
