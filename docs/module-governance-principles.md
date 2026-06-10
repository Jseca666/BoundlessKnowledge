# 新增模块治理与存放原则

本文是人类说明。机器真相在：

```text
system/module-governance-policy.json
system/module-layer-model.json
```

## 核心原则

新增任何模块、目录、脚本、schema、workflow、loop、index、Canvas 或长期能力前，先回答这些问题：

1. 它的 `owner_layer` 属于哪一层？
2. 它的 `module_kind` 和边界是什么？
3. 机器真相源在哪里？
4. 文件长期放在哪里，草稿和归档放在哪里？
5. 未来任务通过哪个 route 找到它？
6. 它需要专属 Canvas、共享 Canvas、延期可视化，还是明确不适用？
7. 改动后跑什么校验，什么时候迁移或归档？

如果这些问题说不清，先放草稿区或 inbox，不要直接变成系统默认入口。

## 层级判断

系统分层以 `system/module-layer-model.json` 为机器真相。这里的表只做人读说明。

特别注意：`owner_layer`、`storage_path`、`lifecycle_status`、Canvas `view_level` 是四条不同轴：

- `owner_layer`：模块职责归属，比如知识内容、系统治理、机器基础设施。
- `storage_path`：文件放在哪里，只是存放证据，不自动决定归属。
- `lifecycle_status`：current、partial、draft、archive 等生命周期。
- Canvas `view_level`：L0/L1/L2/L3/L4 是图的缩放层级，不是模块职责层。

| 层 | 放什么 | 常见位置 |
| --- | --- | --- |
| 知识内容层 | 来源、原子笔记、领域图、综合产物、知识质量评估 | `10-sources/`、`20-notes/`、`30-maps/domains/`、`40-synthesis/`、`60-evals/` |
| 系统治理层 | 路由、信息地图、模块治理、诊断、审查、闭环、技术文档、loop 编排 | `system/`、`.agents/skills/`、`docs/` |
| 机器基础设施层 | schema、索引、脚本、工具、本地运行时 | `schemas/`、`scripts/`、`70-indexes/`、`system/tool-map.json` |
| 视觉投影层 | 架构图、领域图、流程图、项目图 | `30-maps/canvas/` |
| 项目消费层 | Codex context pack、项目工作流、项目上下文图 | `50-workflows/`、`30-maps/canvas/40-project/` |
| 临时与归档层 | 生命周期状态：未整理输入、草稿、被替代版本、历史材料 | `00-inbox/`、`30-maps/canvas/80-drafts/`、`30-maps/canvas/90-archive/`、`90-archive/` |

系统治理层不是知识内容分类的一部分。它管理知识库自身怎么运转；知识内容分类只管外部世界知识怎么归类。

机器基础设施也不是系统治理层本身。它提供 schema、索引、脚本和工具，让系统能被机器稳定执行和校验。

## 存放口径

不要按文件后缀乱放，要按边界、用途、生命周期和消费者放。

- 同一个模块的机器真相、说明文档、校验脚本和可视化入口可以分散在不同目录，但必须通过 route、information map 和相关 registry 串起来。
- 稳定入口必须登记；未登记内容只能是草稿、暂存或归档。
- Markdown 负责解释，JSON/registry/schema/index 负责让机器可靠读取。
- Canvas 负责视觉推理，不能覆盖系统登记。
- PowerShell 可以做 Windows 本地薄入口；复杂逻辑增长后再迁移到 Node、Python、数据库、索引或服务。

## 子系统文档口径

重要模块和子系统的基准文档、子 agent 文档、skill 入口都按根 `AGENTS.md` 的薄入口模式处理：只放角色、阅读顺序、机器真相、路由指针和通用约束。

一旦某个模块会长期增长，就要拆出文档地图或专题文档。入口不承载内部全部规则；架构、边界、workflow、校验、视觉审查、操作说明等各自放到有边界的文件，并通过机器登记串起来。

Canvas 子系统当前样板：

```text
system/canvas-docs-map.json
docs/canvas/README.md
docs/canvas/*.md
```

## 可视化覆盖口径

重要系统结构不能只靠人眼记住“应该有图”。新增或升级模块时，必须同步检查：

```text
system/visual-coverage-map.json
```

每个闭环模块必须有一个可视化覆盖决策：

- `dedicated_required`：必须有专属 Canvas。
- `shared_required`：由共享 Canvas 覆盖。
- `deferred`：暂缓画图，但必须写原因和复审触发条件。
- `not_applicable`：当前阶段不需要图，但也必须写原因和复审触发条件。

这道门由 `scripts/validate-system.ps1` 校验。以后出现重要系统图漏登记，应该先修 visual coverage map 和校验门，而不是只补某一张图。

## 校验口径

系统变更默认先跑核心校验：系统登记、诊断契约、审查契约、索引构建和知识库校验。涉及 Canvas、诊断契约、审查契约或知识内容时，再按 `system/module-governance-policy.json` 的 `conditional_validation` 追加对应校验。

这不是放松校验，而是避免把所有问题都变成一刀切的负面约束；校验应该跟随实际受影响面。

## 新增模块检查表

```text
1. diagnose-layer
2. choose-artifact-form
3. choose-storage-home
4. declare-canonical-truth
5. plan-documentation-boundary
6. decide-visual-coverage
7. register-route
8. update-information-map
9. attach-validation
10. record-lifecycle
```

这套检查表以后也适用于新的知识领域、工作流、工具、画布系统、数据索引、自动化循环和项目消费包。

## 系统结构治理模块

新增稳定模块、子系统、长期能力或跨模块关系时，不再只靠 `system/module-layer-model.json` 贴层级标签。先进入：

```text
system/system-structure-governance.json
system/module-relationship-map.json
```

判断顺序是：先形成结构判断包，再选择 `attach_to_existing_module`、`create_child_module`、`create_peer_module`、`create_new_branch`、`defer_as_draft` 或 `merge_or_retire`。判断完成后再同步 route、information map、closure、visual coverage、Canvas 和 validation。

`system/module-layer-model.json` 只是结构治理模块输出的 owner_layer / module_kind 快照，不再单独承担“该归属还是新建分支”的专业判断。

## 旧内容责任继承

新系统模块不是只负责未来新增内容。只要它接管了一个职责边界，就必须审查这个边界里已经存在的旧文件、旧 Canvas、旧 route、旧规则、旧状态、旧 schema、旧 workflow、旧工具和旧文档。

处理结果只能是以下几类之一：

```text
adopt
migrate
deprecate
archive
exempt_with_reason
queue_follow_up
```

不能出现“新模块已经成立，但旧内容仍然没人负责”的状态。无法立即迁移的旧内容，要进入明确的 follow-up、known_gaps 或诊断/审查队列。

## 生效不等于登记

稳定系统模块不能因为“文件已经创建、route 已经登记、Canvas 已经画出来”就被称为生效。登记只说明系统知道它存在；生效必须另有机器可读的激活证明。

当前机器真相在：

```text
system/module-governance-policy.json#module_activation_contract
system/system-closure-map.json#modules.<module_id>.activation_proof
```

激活证明至少要覆盖：route、information-map、closure、module-relationship-map、旧资产审查、visual coverage 和 validation。没有这些证明，只能说模块处于 partial、draft 或 blocked，不能说它已经接管历史系统。

这条规则是“新系统模块必须对旧系统内容负责”的执行层：先审查旧内容，再证明接管，最后才能称为 active/effective。
