# Canvas 子系统文档入口

本文只作为薄入口，不承载 Canvas 子系统的全部规则。机器真相和详细说明分别由路由文件接管。

## 先读顺序

1. `system/canvas-docs-map.json`
2. `system/canvas-system.json`
3. `system/canvas-registry.json`
4. `system/canvas-view-graph.json`
5. 按 `system/route-registry.json` 的 Canvas route 进入具体文件

## 文档分工

- `docs/canvas/architecture.md`：Canvas 子系统为什么存在、连接哪些系统真相。
- `docs/canvas/file-placement.md`：Canvas 文件创建、目录、命名、生命周期。
- `docs/canvas/view-boundaries.md`：图层级、图类别、主对象、边界和 `not_for`。
- `docs/canvas/data-separation.md`：机器图数据和人读画布数据怎么分。
- `docs/canvas/visual-audit.md`：视觉审查记录和布局改进依据。
- `docs/canvas/obsidian-workflow.md`：Obsidian 打开、浏览和常见显示问题。

## 填写原则

- 本入口只放一般性阅读顺序和文档路由。
- 具体规则放到对应专题文档，并同步 `system/canvas-docs-map.json`。
- 机器事实以 `system/canvas-system.json`、`system/canvas-registry.json`、`system/canvas-view-graph.json` 为准。
- `.canvas` 是视觉入口，不是系统行为真相来源。
- 新增 Canvas 子系统文档前，先判断它是否有独立边界；有就新建专题文档并登记，不要继续堆到入口文件里。
