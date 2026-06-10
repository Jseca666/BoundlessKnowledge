---
id: domain-map-20260605-canvas-file-planning
title: "Canvas 文件放置规划"
type: domain-map
status: active
created: 2026-06-05
updated: 2026-06-06
tags:
  - canvas
  - knowledge-architecture
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - domain-map-20260605-domain-taxonomy-seed
---

# Canvas 文件放置规划

Canvas 的机器登记真相在：

```text
system/canvas-registry.json
system/canvas-view-graph.json
```

详细人类说明在：

```text
docs/canvas/file-placement.md
docs/canvas/data-separation.md
```

本目录下的 `.canvas` 文件是 Obsidian 视觉架构视图，主要给人读。它不仅用于上层导航，也用于模块内部结构、workflow、dataflow、skill、schema、tool、loop、diagnostic 和 project context。机器读取图层级、父子关系和跳转关系时，应优先读 `system/canvas-view-graph.json`。

## 目录

- `00-entry/`：视觉入口图，只放最高层导航。
- `10-system/`：知识库系统自身的可视化总目录。
- `10-system/00-overview/`：系统总览图，先读这里理解整体模块关系。
- `10-system/10-subsystems/`：系统子模块下钻图，所有模块内部结构继续按子目录放置。
- `10-system/10-subsystems/canvas-system/`：Canvas 可视化子系统图。
- `10-system/10-subsystems/diagnostic-system/`：诊断与系统修复模块图。
- `10-system/10-subsystems/system-closure/`：系统闭环与模块覆盖治理图。
- `20-knowledge/`：知识内容面的分类、领域和知识地图。
- `20-knowledge/10-domain-taxonomy/`：知识领域分类体系图。
- `30-workflow/`：入库、检索、质量门、Codex context pack 等流程图。
- `40-project/`：具体项目相关上下文图。
- `80-drafts/`：未稳定草图和临时脑图。
- `90-archive/`：被替代但需要追溯的历史画布。

新增 Canvas 不应直接放在本目录根部。临时导入也应先放到 `80-drafts/`。

当前常用入口：

```text
00-entry/kb-navigation-index.canvas
10-system/00-overview/kb-system-architecture.canvas
10-system/10-subsystems/diagnostic-system/diagnostic-system-architecture.canvas
10-system/10-subsystems/canvas-system/canvas-system-architecture.canvas
10-system/10-subsystems/canvas-system/canvas-directory-layout.canvas
10-system/10-subsystems/system-closure/system-closure-architecture.canvas
20-knowledge/10-domain-taxonomy/domain-taxonomy-overview.canvas
```

## 最高规格定位

Canvas 在本项目里不是普通画图文件夹，而是“可视化架构系统”。它负责把长期稳定的结构变成可浏览、可下钻、可回链、可审查的视觉入口。

优先建图的对象包括：系统总览、模块内部结构、workflow/dataflow、skill/agent 入口、schema/registry 契约、tool/runtime、loop/state、diagnostic/repair closure、知识领域地图和项目上下文图。

每张稳定图都要有机器登记。人从 `.canvas` 看结构，Codex 从 `system/canvas-registry.json` 和 `system/canvas-view-graph.json` 找当前图、父子图和 source_of_truth。

通用布局规则：除 `00-entry/` 里的纯导航入口图外，所有 current / active 结构图都应把主结构、流程、数据流、状态或 taxonomy 放在左侧/主区域；父图、子图和相关图跳转入口统一收束到右侧独立纵向导航栏，导航线不穿过主结构。

图制作边界和文件系统边界同等重要。每张 current / active 图都必须在 `system/canvas-registry.json` 声明 `view_level`、`view_category`、`primary_subject`、`boundary` 和 `not_for`，避免导航图、系统图、模块图、taxonomy 图、workflow 图和项目图互相混用。
