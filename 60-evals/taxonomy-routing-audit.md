---
id: eval-20260605-taxonomy-routing-audit
title: "Taxonomy Routing Audit"
type: eval
status: active
created: 2026-06-05
updated: 2026-06-05
tags:
  - taxonomy
  - routing
  - eval
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - domain-map-20260605-domain-taxonomy-seed
  - domain-map-20260605-domain-taxonomy-overview
---

# Taxonomy Routing Audit

## Result

Pass. The taxonomy-refinement loop completed first-pass level-3 coverage for all registered level-2 categories.

## Counts

- Level 1: 6
- Level 2: 45
- Level 3: 450
- Level-2 groups with refined status: 45
- Run logs: 45
- Output summaries: 45
- Blocked units: 0

## Checks

- Machine truth remains in `30-maps/domains/domain-taxonomy.registry.json`.
- Each level-2 group has 10 level-3 direction clusters.
- Each refined level-3 entry has `id`, `code`, `name`, and `scope`.
- Loop state is `completed` with latest run `2026-06-05-045`.
- No formal pending status remains in the taxonomy registry.

## Residual Risk

This is a v0.1 structural taxonomy. Real incoming sources should still be sampled against the routing guide. If repeated taxonomy_gap marks appear around the same topic, start a new refinement loop for that local area instead of bloating AGENTS.md.
