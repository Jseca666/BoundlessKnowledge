# 审查模块

本文是审查模块的人类入口。机器真相在：

```text
system/reviews/review-system.json
system/reviews/review-queue.json
system/reviews/review-docs-map.json
schemas/review-record.schema.json
```

## 作用

审查模块负责“主动检查和发现问题”。它可以审系统内部结构，也可以审外部知识质量。

它不替代诊断模块。审查发现明确缺陷后，才把缺陷交给诊断去追根因、定责任层和组织修复闭环。

## 读法

- 系统内部审查：读 `docs/review/system-review.md`。
- 外部知识审查：读 `docs/review/knowledge-review.md`。
- Canvas 视觉审美审查：读 `docs/review/canvas-visual-aesthetic-review.md`。
- 视觉入口：读 `30-maps/canvas/10-system/10-subsystems/review-system/review-system-architecture.canvas`。

## 最小输出

```text
Review id or queue status:
Review class:
Scope:
Evidence paths:
Criteria:
Findings:
Risk assessment:
Handoff decision:
Validation:
Review acceptance:
```
