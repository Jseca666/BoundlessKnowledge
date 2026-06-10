---
name: diagnostic-system
description: Start the knowledge-base diagnosis module before repair, system upgrade, route changes, Canvas fixes, schema changes, tool fixes, or root-cause analysis.
---

# Diagnostic System

This is a thin skill entrypoint. It only routes into the diagnostic module.

Read order:

- `system/route-registry.json` route `diagnostics`
- `system/diagnostics/diagnostic-system.json`
- `system/diagnostics/issue-repair-queue.json`
- `schemas/diagnostic-issue.schema.json`
- `system/information-map.json`

Use this skill when the user asks for diagnosis, root cause, reason analysis, repair closure, or when a local fix might actually be a system upgrade.

Boundary:

- Machine truth, workflow, schema and durable issue fields live in the routed JSON/schema files.
- This entry may state general diagnostic principles only: diagnose before repair, treat incidents as evidence rather than root problems, route repairs to the owning layer, and capture recurring issues durably.
- Do not add local module methods, output templates or special-case rules here.
