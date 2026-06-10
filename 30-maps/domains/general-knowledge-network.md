---
id: domain-map-20260605-general-knowledge-network
title: "General Knowledge Network"
type: domain-map
status: seed
created: 2026-06-05
updated: 2026-06-05
tags:
  - knowledge-map
  - knowledge-ops
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - concept-20260605-evidence-first-knowledge
workflows:
  - workflow-20260605-kb-retrieval-context-pack
---

# General Knowledge Network

## Scope

This map describes the first-level structure of the knowledge base.

## Map

```mermaid
flowchart TD
    Sources["Source Records"] --> Notes["Atomic Notes"]
    Notes --> Concepts["Concepts"]
    Notes --> Claims["Claims"]
    Notes --> Methods["Methods"]
    Concepts --> Maps["Knowledge Maps"]
    Claims --> Synthesis["Synthesis Briefs"]
    Methods --> Workflows["Codex Workflow Packs"]
    Synthesis --> Workflows
    Workflows --> Evals["Retrieval Evals"]
```

## Key Nodes

| Node | Meaning | Related entries |
| --- | --- | --- |
| Source Records | Traceable source metadata | `10-sources/` |
| Atomic Notes | Reusable smallest knowledge units | `20-notes/` |
| Knowledge Maps | Relationship views | `30-maps/` |
| Workflow Packs | Codex-facing procedures | `50-workflows/` |

## Open Questions

- Which domains should be seeded first?
- Which external search and paper sources should be automated first?
