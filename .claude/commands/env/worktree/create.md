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
