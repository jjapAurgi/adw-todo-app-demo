---
description: Start all services (infra, backend, frontend) for a specific worktree
allowed-tools: Bash
---

# Start Worktree Services

## Variables

WORKTREE_PATH:         $1 — Ruta absoluta al worktree
COMPOSE_PROJECT_NAME:  $2 — Nombre del proyecto Docker Compose
POSTGRES_PORT:         $3 — Puerto de PostgreSQL
DATABASE_URL:          $4 — URL de conexión a la base de datos
PORT:                  $5 — Puerto del backend
VITE_PORT:             $6 — Puerto del frontend

## Instrucciones

- Las variables de entorno vienen como argumentos — no es necesario leer `.env.local`
- La infra usa `COMPOSE_PROJECT_NAME` + `POSTGRES_PORT` de los argumentos recibidos
- Usar `run_in_background: true` para backend y frontend
- Si un puerto ya está en uso, informar pero no fallar

## Workflow

1. Usar las variables recibidas como argumentos:
   COMPOSE_PROJECT_NAME=$2, POSTGRES_PORT=$3, DATABASE_URL=$4, PORT=$5, VITE_PORT=$6

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
