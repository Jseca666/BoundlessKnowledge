---
id: domain-map-20260605-domain-taxonomy-seed
title: "知识领域门类规划"
type: domain-map
status: active
created: 2026-06-05
updated: 2026-06-06
tags:
  - domain-taxonomy
  - knowledge-architecture
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - domain-map-20260605-general-knowledge-network
  - domain-map-20260606-domain-taxonomy-baseline
  - domain-map-20260605-domain-taxonomy-overview
  - domain-map-20260605-domain-taxonomy-routing-guide
workflows:
  - workflow-20260605-kb-retrieval-context-pack
---

# 知识领域门类规划

本文只作为领域分类体系的薄入口，不承载完整分类表、路由规则、loop 状态或运行历史。

## 先读顺序

1. `30-maps/domains/domain-taxonomy.docs.json`
2. `30-maps/domains/domain-taxonomy.registry.json`
3. `30-maps/domains/domain-taxonomy-baseline.md`
4. `30-maps/domains/domain-taxonomy-routing-guide.md`
5. `30-maps/domains/domain-taxonomy-overview.md`
6. `system/loops/taxonomy-refinement/README.md`
7. `60-evals/taxonomy-routing-audit.md`

## 机器真相

```text
30-maps/domains/domain-taxonomy.registry.json
30-maps/domains/domain-taxonomy.docs.json
```

逐项打磨 loop 的机器状态在：

```text
system/loop-registry.json
system/loops/taxonomy-refinement/loop.json
system/loops/taxonomy-refinement/queue.json
system/loops/taxonomy-refinement/state.json
system/loops/taxonomy-refinement/runner-contract.json
system/loops/taxonomy-refinement/runs/
system/loops/taxonomy-refinement/outputs/
```

## 文档分工

- `domain-taxonomy.docs.json`：文档地图、边界和 loop 资产路由。
- `domain-taxonomy.registry.json`：分类树机器真相。
- `domain-taxonomy-baseline.md`：一级、二级、字段和当前状态的人读基准。
- `domain-taxonomy-routing-guide.md`：分类路由顺序、决策规则和质量门。
- `domain-taxonomy-overview.md`：完整三级方向簇的人读总览。
- `taxonomy-refinement/README.md`：逐项打磨 loop 的薄入口。
- `taxonomy-refinement/runs/` 与 `outputs/`：运行记录和人读 summary。

## 不负责

- 不在本文维护完整一级/二级/三级表。
- 不在本文维护分类路由例子。
- 不在本文维护 loop 运行历史。
- 不把 Markdown 作为分类行为真相来源。
