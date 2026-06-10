---
id: eval-20260605-retrieval-quality
title: "Retrieval Quality Baseline"
type: eval
status: seed
created: 2026-06-05
updated: 2026-06-05
tags:
  - eval
  - retrieval
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - workflow-20260605-kb-retrieval-context-pack
workflows:
  - workflow-20260605-kb-retrieval-context-pack
---

# Retrieval Quality Baseline

## Purpose

Use these cases to check whether the knowledge base helps Codex retrieve relevant context without flooding the task with unrelated material.

## Test Cases

| Query | Expected retrieval |
| --- | --- |
| "如何让 Codex 项目调用这个知识库？" | `workflow-20260605-kb-retrieval-context-pack` |
| "知识条目为什么需要证据？" | `concept-20260605-evidence-first-knowledge` |
| "这个知识库的第一层关系是什么？" | `domain-map-20260605-general-knowledge-network` |

## Pass Criteria

- Top result includes the expected entry.
- Retrieved entries include source or confidence metadata.
- Codex can explain why the entry is relevant.
