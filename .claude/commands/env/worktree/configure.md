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
