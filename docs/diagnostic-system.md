# 诊断与系统修复模块

本文是人类说明。机器真相以这些文件为准：

```text
system/diagnostics/diagnostic-system.json
system/diagnostics/diagnostic-layer-matrix.json
system/diagnostics/failure-learning-loop.json
system/diagnostics/issue-repair-queue.json
schemas/diagnostic-issue.schema.json
scripts/validate-diagnostics.ps1
```

## 作用

诊断模块负责在修复前判断问题属于哪一层，防止“局部现象一改完就说系统升级”。它不是单独的找原因工具，而是诊断驱动协同升级的入口：先冻结事故表现，再定位根因问题和系统调节目标，最后决定是 `local_repair`、`system_upgrade` 还是 `blocked_investigation`。

## 事故不是问题本身

事故、截图、报错、画布线条遮挡、某个文件缺字段，只是问题的体现。诊断记录必须分成三层：

- `incident_manifestation`：看到的事故表现和证据面。
- `root_problem`：导致同类事故复发的系统机制缺口。
- `system_regulation_target`：需要被调节或升级的规则、schema、route、workflow、validator、Canvas 或模块边界。

从 `diag-20260607-incident-root-problem-separation-missing` 起，新的 captured `system_upgrade` 诊断记录缺少这三层时，`scripts/validate-diagnostics.ps1` 应失败。

## 顶层修复原则

诊断修复的目标不是不断补洞和增加禁止项，而是找到产生洞的机制。

优先顺序是：

1. 先修正向模型：模块边界、数据流、状态机、路由、registry、目录归属、生成机制。
2. 再考虑负面护栏：forbidden pattern、硬校验、审查门。
3. 新增护栏前必须问：它保护的是不是系统不变量？有没有旧规则可以合并、降级或删除？

## 核心流程

```text
1. freeze-failing-path
2. name-symptom
3. separate-incident-and-root-problem
4. trace-lower-evidence
5. trace-upper-principle
6. identify-failed-mindset
7. classify-owner
8. decide-repair-class
9. plan-coordinated-upgrade
10. scan-same-class-and-sibling-surfaces
11. design-positive-model-repair
12. decide-constraint-need
13. repair-at-owner-layer
14. migrate-governed-assets
15. upgrade-quality-gate
16. sync-visual-projection
17. validate
18. diagnosis-accept
19. audit-diagnostic-performance
20. decide-failure-learning-loop
21. open-controlled-learning-loop
22. surface-diagnosis-summary
```

## 同类面扫描

当问题被判定为 `system_upgrade`，或用户指出“不只是这个子系统一个点的问题”时，诊断不能只修被点名对象。正确顺序是先确认 `observed_instance` 和 `failure_class`，再检查同类资产、兄弟模块、同层视图、相关 route、schema、validator、workflow、review 和 Canvas 投影。

## 诊断自审

用户指出“诊断不对”“漏诊”“诊断模块失职”时，不仅要修目标对象，还要反查诊断过程为什么没有提前发现。此时诊断模块自身也必须进入 owning repair layer，并记录 `diagnostic_self_audit`。

## OR 借鉴层

这次借鉴 `C:\Users\dzw\Desktop\or` 的诊断模块，只迁移可复用方法，不复制 OR 的项目数据、数据库服务或自动自我改写行为。

- `diagnostic-layer-matrix.json`：用于判断问题属于哪一层，避免看到局部事故就直接修局部。
- `failure-learning-loop.json`：用于把高风险或反复出现的问题转成受控学习循环：postmortem -> proposal -> regression guard -> promotion decision。
- `issue-repair-queue.json`：从 `diag-20260610-or-diagnostic-failure-learning-adoption` 起，新的 captured `system_upgrade` 记录必须写明 `failure_learning_decision.status` 和 `reason`。

失败学习循环只产生受控改进对象。它不能自动晋升规则、写入长期记忆、修改外部系统或绕过人工确认。
