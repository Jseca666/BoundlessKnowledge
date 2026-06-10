# 系统闭环总表

本文只解释系统闭环总表的用途。机器真相在 `system/system-closure-map.json`。

## 作用

系统闭环总表用来回答：每个模块是否已经具备入口、机器真相、路由、校验、文档边界、可视化、诊断接入和生命周期。

当前可视化入口是 `30-maps/canvas/10-system/10-subsystems/system-closure/system-closure-architecture.canvas`。

## 使用时机

- 新增模块后，检查是否进入闭环总表。
- 感觉模块太多、边界变乱时，先看闭环状态和 known gaps。
- 修复系统问题后，确认受影响模块的闭环状态是否需要更新。
- 新增审查模块后，确认审查、诊断、可视化和校验是否形成上游发现到下游修复的闭环。

## 边界

- 它不替代 `system/information-map.json`。
- 它不替代 `system/route-registry.json`。
- 它不替代各模块自己的 docs map、registry、schema 或 validator。
- 它只做跨模块闭环审计和缺口记录。

## 当前读法

- `closed` 表示该模块有稳定入口、机器真相、路由、校验、文档或可视化/诊断接入。
- `partial` 不一定是故障；它表示模块处于当前阶段可用，但仍有明确 known gaps 和 next_action。
- Canvas 相关闭环必须同时看 `validate-canvas.ps1` 和 `audit-canvas-visual.ps1`，因为结构正确不等于视觉可读。
- 归档旧图如果仍然可见，必须有 archive 标识和跳转到当前图的 replacement navigation。
- 审查模块是诊断的上游：审查负责发现和分级，诊断负责根因、责任层和修复闭环。
