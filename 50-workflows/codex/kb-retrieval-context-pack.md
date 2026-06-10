---
id: workflow-20260605-kb-retrieval-context-pack
title: "KB Retrieval Context Pack"
type: workflow
status: seed
created: 2026-06-05
updated: 2026-06-05
tags:
  - codex-workflow
  - retrieval
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - concept-20260605-evidence-first-knowledge
  - domain-map-20260605-general-knowledge-network
workflows: []
---

# KB Retrieval Context Pack

## Use When

Use this workflow when a Codex project needs domain context from this knowledge base before planning, coding, reviewing, or researching.

## Inputs

- User task.
- Target project path.
- Relevant domain, technology, or industry keywords.

## Retrieval Path

1. Read `70-indexes/catalog.json`.
2. Select entries whose `title`, `tags`, `domains`, or `type` match the task.
3. Prefer `50-workflows/` first for operating procedures.
4. Read linked `40-synthesis/` and `20-notes/`.
5. Check referenced `10-sources/` records before making factual claims.

## Procedure

1. Identify the task type: research, architecture, implementation, review, test, deployment, or writing.
2. Retrieve the smallest relevant set of knowledge entries.
3. Separate stable principles from time-sensitive facts.
4. Browse or refresh external facts when dates, versions, prices, regulations, APIs, or current GitHub metrics matter.
5. Apply the knowledge to the project and cite entry ids in the reasoning or final summary.

## Output

- A short list of knowledge entries used.
- Any source records checked.
- Any missing evidence or stale facts.
- The project-specific plan or implementation.

## Quality Gate

- Do not rely on stale GitHub metrics without refreshing them.
- Do not cite an atomic note as evidence if it has no source and the claim is factual.
- Do not import broad context when a narrow workflow pack is enough.
