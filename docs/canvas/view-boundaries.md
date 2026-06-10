# Canvas 视图边界

本文是人类说明。机器真相在：

```text
system/canvas-system.json
system/canvas-registry.json
system/canvas-view-graph.json
system/module-layer-model.json
```

## 基本原则

Canvas 的图制作边界和文件目录边界同等重要。目录解决“放在哪里”，视图边界解决“这张图应该表达什么”。

每张 current / active 图都必须在 `system/canvas-registry.json` 声明：

```text
view_level
view_category
primary_subject
boundary
not_for
```

## 视图粒度

注意：下面的 `L0` 到 `L4` 是 Canvas 视图缩放级别，不是模块职责分层。模块的 `owner_layer` 以 `system/module-layer-model.json` 为准。

```text
L0 视觉导航入口：只负责去哪儿
L1 系统总览：表达模块和跨模块数据流
L2 模块架构：表达单个模块内部结构、owner 文件、输入输出和质量门
L3 workflow/dataflow：表达执行顺序、状态转换、工具和 gate
L4 contract/state：表达 schema 字段、registry 契约、issue 状态、loop 状态或目录边界
```

## 视图类别

常用类别包括：

```text
navigation
system-overview
module-architecture
directory-boundary
workflow
dataflow
taxonomy
knowledge-map
skill
schema
tool
loop
diagnostic
project-context
archive
```

## 边界规则

- 一张 current / active 图只能有一个主对象。
- 跨边界内容要用 child view、related view、source_of_truth 或右侧导航栏连接，不要塞进主图。
- 导航图不表达架构、流程、分类细节或数据流。
- 总览图不展开所有模块内部细节。
- 模块图不替代系统总览图。
- workflow / dataflow 图不替代目录布局图或领域分类图。
- taxonomy / knowledge map 不解释系统运行机制。
- project 图不重定义全局系统真相。
- directory-boundary 图只解释放置边界，不解释每个模块的全部内部行为。

## 右侧导航栏

除纯导航入口图外，所有 current / active 的非导航结构图都遵守：

```text
左侧 / 主区域：主结构、workflow、dataflow、taxonomy、状态转换、知识结构或项目上下文
右侧导航栏：父图、子图、相关图和返回入口
```

右侧导航栏里的 `.canvas` 文件节点只承担点击跳转职责，不承担信息解释职责。稳定结构图里，文件节点应该缩成小按钮；跳转目的由旁边的 `nav-label-*` 中文标签说明。如果需要说明它对应当前图里的哪个模块，就从这个 `nav-label-*` 直接拉一条 `bridge-*` 线到对应模块。

正文区和右侧导航栏之间必须保留清晰留白通道。current / active 的非导航结构图建议留约 220px，低于 200px 会被视觉审查视为拥挤，因为解释线会贴着正文模块走，读起来像结构线和导航线混在一起。

导航线不能穿过主结构。这个规则由 `scripts/validate-canvas.ps1` 做最低限度检查，视觉审查记录见 `docs/canvas/visual-audit.md`。


### L0 / L1 / L2 父子关系

L0 入口图是跳转入口，不是所有图的真实父级。当前规则是：

- L0 的 `child_views` 只登记 L1 主干视图。
- L2 `system-subsystem` 图的 canonical parent 是 L1 系统总览。
- L0 可以放 L2 快捷按钮，但必须视觉嵌套在对应 L1 主干下面，并且不能改变 `canvas-view-graph` 的父子关系。
- L2 子系统图向上返回 L1 系统总览；需要回总入口时再从系统总览返回。

## L0 入口图

L0 入口图不是系统说明页，也不是机器真相索引页。它只负责打开当前下层 `.canvas` 视图。

- 可以放标题、短说明和分组文字。
- 分组口径必须服从 `system/module-layer-model.json` 和 `system/canvas-view-graph.json`，不能用主观栏目混合系统总览、知识内容、治理子系统和机器基础设施。
- 文件节点只能指向已登记的 `.canvas` 视图。
- 每个 `.canvas` 文件节点都必须登记到 `navigation_nodes`。
- 每个导航文件节点旁边都必须有清晰中文目的标签，例如“返回：总导航入口”“相关：系统闭环总表”。
- 不放 JSON、Markdown、脚本等机器真相文件节点。
- 不放 future placeholder 作为导航目标。
- 不用入口图表达架构、taxonomy 细节、workflow、dataflow 或治理关系。

这条规则同样由 `scripts/validate-canvas.ps1` 检查。

## 导航标签

文件节点默认显示文件名，容易被 Obsidian 缩略或截断，所以文件名不能承担导航说明。所有 current / active 图中，只要一个文件节点指向已登记的 Canvas 视图，就必须配一个 `nav-label-{node_id}` 文本节点，直接写明跳转目的。非导航结构图中的导航文件节点应保持为小按钮，让 `nav-label-*` 承担唯一的人读解释。

## 上下文连接线

导航栏可以和当前图里的对应内容建立关系，但不要重复做“导航解释”和“正文对应标记”两套结构。

- 右侧 `nav-label-*` 是唯一的人读解释。
- 小型 `.canvas` 文件节点只负责点击跳转。
- `bridge-*` 线从 `nav-label-*` 直接连到对应的当前内容模块，线的标签以“对应：”开头。
- 这种关系不表示数据流、执行顺序、依赖关系或机器真相。
- `bridge-anchor-*`、`content-marker-*` 和 `context-route-*` 只作为例外：当一条直接解释线会严重遮挡时才使用。
- 如果使用 `context-route-*`，`context-rail-*`、`context-corridor-*`、`context-port-*` 只能是近似不可见的 group 节点，不能做成可见文字卡、彩色小方块或点卡。
- L0 入口图不用上下文连接线或内容标记，因为它没有主内容区。

## 颜色语义

颜色是视图内部的语义提示，不是全系统统一事实字段。current / active 图必须在 `system/canvas-registry.json` 声明 `color_semantics`，并在图内显示 `color-legend`。

- 系统、模块、诊断、审查和 workflow 图默认使用系统角色色板，区分机器真相、治理方法、知识内容、来源输入、下游交接和风险诊断。
- 领域分类图使用知识领域家族色板，颜色只帮助浏览分类结构，不表示系统状态。
- loop 图可以使用 loop 状态色板，表达运行面、状态更新、handoff gate 和诊断触发。
- 入口图使用层级导航色板，表达 L1 主干和 L2 快捷入口，不表达结构数据流。

机器不得从 `.canvas` 的颜色反推真相。机器读取 palette、source_of_truth、父子关系和 view graph 时，仍以 JSON registry 为准。

## 线路摆放

线条本身也是视图边界的一部分。它不能只在语义上正确，还要在视觉上不遮挡阅读路径。

- 线不能穿过非端点卡片、分区横幅、导航标签、文件节点或机器真相区域。
- 低价值引用关系优先用分区、颜色、标题、标签或文件节点位置表达，不优先画线。
- 导航栏内部不强制用竖线串联；如果竖线会穿过 `nav-label-*`，就不要画。
- 从分区标题向多张子卡片发散的长斜线通常应省略，由空间分组表达层级。
- 机器真相文件节点可以成组摆放，不必向主卡片逐条拉线。
- 每次线路调整后运行 `scripts/audit-canvas-visual.ps1 -Strict`，没有线穿节点和长斜线警告后才接受。

这条规则由 `scripts/validate-canvas.ps1` 检查。

## 归档旧图

`30-maps/canvas/90-archive/` 里的图可以保留历史布局，但不能看起来像当前系统真相。只要旧图仍然留在 Canvas 系统里可见，就必须：

- 在图上放 `archive-status-note`，明确说明它是归档或 legacy 图。
- 在右侧放一个紧凑 `.canvas` 文件按钮，跳到 registry 里的 `replaced_by` 当前图。
- 文件按钮旁边放 `nav-label-*` 中文标签，说明“当前：...”。
- 不要求重画旧图全部正文，但不能让用户误以为旧图仍是现行架构。

这条规则由 `scripts/validate-canvas.ps1` 检查。

### 颜色 token 稳定性

颜色语义必须同时满足两件事：一是有 view-scoped palette 说明颜色在当前图里的含义，二是颜色 token 本身能被 Obsidian Canvas 稳定渲染。

current / active 图中，palette role、allowed_colors、节点颜色和边颜色只能使用：
```text
1 / 2 / 3 / 4 / 5 / 6
#RRGGBB
```

不要使用 `cyan`、`purple`、`red`、`yellow`、`green`、`orange` 这类英文命名色作为受治理 token。需要更细颜色时再用十六进制色，并在 `color-legend` 和 registry palette 中登记。
