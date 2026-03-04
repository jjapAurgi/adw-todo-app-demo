---
description: Stop all services and remove a git worktree
allowed-tools: Bash
---

# Destroy Worktree

## Variables

WORKTREE_PATH: $1 — Ruta al worktree (relativa o absoluta)

## Instrucciones

Ejecutar el script `adws/bin/worktree/destroy` pasándole la ruta del worktree.

## Workflow

1. Ejecutar: `adws/bin/worktree/destroy {WORKTREE_PATH}`
2. Confirmar al usuario que el worktree ha sido eliminado
