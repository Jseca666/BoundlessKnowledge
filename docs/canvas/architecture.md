# Canvas 子系统架构

Canvas 是知识库系统的可视化影子层。

它像文件系统、模块边界、路由、数据流、registry、workflow、diagnostic、taxonomy 和项目上下文投出来的视觉影子：帮助人看见结构、理解入口、发现错位，但不替代真正的机器真相。

## 机器真相

Canvas 子系统的机器真相由这些文件决定：

```text
system/canvas-system.json
system/canvas-registry.json
system/canvas-view-graph.json
system/canvas-docs-map.json
system/visual-coverage-map.json
system/information-map.json
system/route-registry.json
```

`.canvas` 文件本身只作为视觉投影。图上可以显示摘要、关系、跳转入口和设计判断，但不能覆盖 registry、schema、workflow、index 或 validator 的机器事实。

## 可视化影子

这个比喻很重要：Canvas 不是另一个文件系统，也不是“画出来就算登记了”。

它的来源包括：

- 文件系统路径和目录层级。
- `information-map` 里的模块边界与数据流。
- `route-registry` 里的任务入口。
- `canvas-registry` 里的视图状态、位置和生命周期。
- `canvas-view-graph` 里的无坐标导航网络。
- `visual-coverage-map` 里的必画、共享、延期和不适用决策。
- domain、workflow、loop、schema、diagnostic、tool 等 registry。

它的边界也要明确：

- Canvas 文字和坐标不决定系统真相。
- Canvas 不能替代 route、information map、schema、registry、index 或 validator 更新。
- 如果可视化影子和机器真相不一致，先修 owning registry/map，再更新 Canvas。

## 最高规格定位

Canvas 不只是画图文件夹，也不只是上层导航。

它承担五件事：

1. 帮人快速理解系统架构、知识分类、工作流和项目上下文。
2. 把机器真相文件投影成可浏览、可讨论、可迭代的视觉视图。
3. 通过登记和校验避免旧图当新图、草稿当真相、图和系统不同步。
4. 把模块内部结构、skill、schema、tool、loop、diagnostic gate、dataflow 等结构性对象变成可检查的图。
5. 在新增重要系统能力前，先作为设计面板帮助判断边界、输入输出、责任层、校验和导航关系。

## 数据分层

Canvas 相关数据分两层：

```text
机器读：system/canvas-registry.json + system/canvas-view-graph.json + system/canvas-docs-map.json + system/visual-coverage-map.json
人类读：30-maps/canvas/**/*.canvas + docs/canvas/*.md
```

`.canvas` 里有坐标、颜色、卡片文字和视觉分组，适合 Obsidian 浏览；`canvas-view-graph.json` 去掉这些布局噪音，只保留 view、path、parent/child、source_of_truth 和 navigation edge。

## 数据流

```text
filesystem / information-map / route-registry / taxonomy / workflows
  -> visual-coverage-map decides whether visual coverage is required
  -> canvas-registry resolves view family and current view
  -> canvas-view-graph provides layout-free machine navigation
  -> .canvas files provide visual shadow and Obsidian jump points
  -> Obsidian for human browsing
  -> Codex reads registries first, then canvas if visual context is needed
```

## 视图族

一个 `view_family` 表示一组同类图，比如“知识库系统架构”或“Canvas 子系统架构”。同一个 `view_family` 最多只能有一张 `current` 图。

以后图多了，Codex 和你都应该先找 `current`，而不是猜哪张最新。

## 视图粒度与边界

Canvas 采用 L0-L4 的多级粒度，并用 `view_category`、`primary_subject`、`boundary` 和 `not_for` 防止图越界。

详细规则由独立专题文档接管：

```text
docs/canvas/view-boundaries.md
```

## 视图导航网络

Canvas 不是一个大目录里的平面图集合，而是一张可上下钻取的视图网络。

- 上层图负责概览和导航，不展开全部细节。
- 下层图负责某个模块、领域或流程的细节。
- 上层图的模块节点旁边应放 `.canvas` 文件节点作为下钻入口。
- 下层图必须放回到父级 `.canvas` 的文件节点，方便返回。
- 父子关系登记在 `system/canvas-registry.json` 的 `parent_views`、`child_views` 和 `navigation_nodes`。

## 更新协议

这些文件变化时，要检查相关 Canvas 是否需要同步：

- `system/information-map.json`
- `system/route-registry.json`
- `system/visual-coverage-map.json`
- `system/tool-map.json`
- `.agents/skills/`
- `schemas/`
- `system/diagnostics/`
- `system/loop-registry.json`
- `30-maps/domains/domain-taxonomy.registry.json`
- `50-workflows/`

修改 Canvas 后至少运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-canvas.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
```
