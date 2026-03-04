---
description: Generate .env.local with deterministic ports for a worktree
allowed-tools: Bash
---

# Isolate Worktree Environment

## Variables

WORKTREE_PATH: $1 — Ruta al worktree (relativa o absoluta)

## Instrucciones

Ejecutar el script `adws/bin/worktree/isolate` pasándole la ruta del worktree.

## Workflow

1. Ejecutar: `adws/bin/worktree/isolate {WORKTREE_PATH}`
2. Reportar EXCLUSIVAMENTE el JSON de salida del script (sin texto adicional)
