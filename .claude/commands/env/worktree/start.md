---
description: Start backend and frontend servers for a specific worktree
allowed-tools: Bash
---

# Start Worktree Servers

## Variables

WORKTREE_PATH: $1 — Ruta al worktree (relativa o absoluta)

## Instrucciones

Ejecutar el script `adws/bin/worktree/start` pasándole la ruta del worktree.
Requiere haber ejecutado `worktree/setup` previamente.

## Workflow

1. Ejecutar: `adws/bin/worktree/start {WORKTREE_PATH}`
2. Informar al usuario de los puertos de backend y frontend
