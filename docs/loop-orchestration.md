# Loop 编排模块

本文只做人读入口。机器真相在：

```text
system/loop-registry.json
system/loops/
system/route-registry.json#loop-orchestration
system/system-closure-map.json#loop-orchestration
```

## 边界

loop-orchestration 是系统治理层模块，负责登记和治理稳定、可重复、可暂停、可恢复的循环。它接管 loop registry、队列、状态、runner 契约、运行记录、handoff 入口、旧 loop 接管和可视化覆盖。

单个 loop 可以服务具体模块。例如 `taxonomy-refinement` 服务知识领域分类，但它作为 loop 资产由 loop-orchestration 统一登记和接管。

## 不负责

- 不保存具体知识分类真相；分类真相在 `30-maps/domains/domain-taxonomy.registry.json`。
- 不替代诊断系统；根因定位和责任层判断仍归 diagnostics。
- 不替代审查系统；review 负责发现和分级，loop 只接管可重复推进。
- 不替代 Canvas 系统；Canvas 只做可视化影子，图布局由 architecture-views 治理。
- 不提前实现无人值守多 loop 调度；等第二个 durable loop 或明确自动化需求出现后再升级运行时形态。

## 当前接管

```text
system/loops/taxonomy-refinement/
```

该 loop 已作为历史资产被 `system/loop-registry.json` 标记为 `adopted_legacy_loop`。它的完成状态在 `state.json`，运行记录在 `runs/`，人读摘要在 `outputs/`。

## 可视化入口

```text
30-maps/canvas/10-system/10-subsystems/loop-orchestration/loop-orchestration-architecture.canvas
```

系统总览图也应提供下钻入口。新增或升级 durable loop 时，同步更新 `system/visual-coverage-map.json` 和 `system/canvas-registry.json`。
