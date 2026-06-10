# Canvas 图数据分层

本文是人类说明。机器真相在：

```text
system/canvas-registry.json
system/canvas-view-graph.json
system/canvas-system.json
system/canvas-docs-map.json
```

## 基本原则

`.canvas` 文件虽然是 JSON，但它主要服务 Obsidian 的视觉布局，不作为机器判断图关系的来源。

机器需要的图数据必须进入：

```text
system/canvas-view-graph.json
```

人类需要的视觉表达保留在：

```text
30-maps/canvas/**/*.canvas
docs/canvas/*.md
30-maps/canvas/README.md
```

## 深层结构图也遵守分层

模块内部图、workflow/dataflow 图、skill 图、schema 图、tool/runtime 图、loop/state 图和 diagnostic/repair 图都不能因为“看起来像系统真相”就直接变成系统真相。

- `.canvas` 负责节点位置、视觉分区、阅读顺序和 Obsidian 跳转。
- `system/canvas-registry.json` 负责视图登记、状态、目录、生命周期和 source_of_truth。
- `system/canvas-view-graph.json` 负责无坐标的父子关系、相关视图和导航边。
- 具体模块事实仍回到对应机器文件，例如 `system/diagnostics/`、`system/loops/`、`schemas/`、`system/tool-map.json` 或 `.agents/skills/`。

这条规则保证 Canvas 可以升级成可视化架构系统，但不会让画布文本、卡片顺序或坐标覆盖机器友好数据流。

## 机器读什么

机器只读稳定、薄、可校验的数据：

- view id
- status
- view family
- view type
- layer
- canvas path
- parent view ids
- child view ids
- related view ids
- source of truth
- navigation edge

这些数据不包含 Obsidian 坐标和视觉文字。

## 人读什么

人主要读：

- Canvas 上的卡片文字
- 节点位置和分组
- 文件节点跳转
- 视觉布局和阅读顺序
- Markdown 说明文档

这些内容可以帮助理解，但不能覆盖机器登记。

## 什么时候提升到机器数据

如果一条关系会影响 Codex 如何找图、读图、下钻、回链、判断 current view 或避免旧图误用，就必须写入：

```text
system/canvas-registry.json
system/canvas-view-graph.json
```

如果只是帮助人看懂画面，例如卡片顺序、颜色、位置、说明句子，则留在 `.canvas`。

## 禁止混入机器图的数据

`system/canvas-view-graph.json` 不应包含这些布局字段：

```text
x
y
width
height
color
text
```

这些字段属于 Obsidian 视觉层。
