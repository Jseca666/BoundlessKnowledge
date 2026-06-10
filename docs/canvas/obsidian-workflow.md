# Obsidian Canvas 工作流

这个仓库可以直接作为 Obsidian vault 打开：

```text
C:\Users\dzw\Documents\无界知识
```

## 推荐打开顺序

1. 打开 Obsidian。
2. 选择 Open folder as vault。
3. 选择 `C:\Users\dzw\Documents\无界知识`。
4. 先看视觉导航入口：

```text
30-maps/canvas/00-entry/kb-navigation-index.canvas
```

5. 从导航入口进入知识库系统架构：

```text
30-maps/canvas/10-system/00-overview/kb-system-architecture.canvas
```

6. 从导航入口进入 Canvas 子系统架构：

```text
30-maps/canvas/10-system/10-subsystems/canvas-system/canvas-system-architecture.canvas
```

7. 从 Canvas 子系统架构进入 Canvas 目录布局：

```text
30-maps/canvas/10-system/10-subsystems/canvas-system/canvas-directory-layout.canvas
```

## 目录规则

Canvas 不再直接放在 `30-maps/canvas/` 根目录。根目录只放 README 和目录。

```text
30-maps/canvas/00-entry/                  最高层视觉入口
30-maps/canvas/10-system/                 系统可视化总目录
30-maps/canvas/10-system/00-overview/     系统总览图，先读这里
30-maps/canvas/10-system/10-subsystems/   系统子模块下钻总目录
30-maps/canvas/10-system/10-subsystems/canvas-system/   Canvas 子系统图
30-maps/canvas/10-system/10-subsystems/diagnostic-system/ 诊断与系统修复图
30-maps/canvas/10-system/10-subsystems/system-closure/ 系统闭环治理图
30-maps/canvas/20-knowledge/              知识内容面的可视化
30-maps/canvas/20-knowledge/10-domain-taxonomy/ 领域 taxonomy 图
30-maps/canvas/30-workflow/               入库、检索、质量门、Codex 工作流
30-maps/canvas/40-project/                项目上下文图
30-maps/canvas/80-drafts/                 未稳定草图
30-maps/canvas/90-archive/                历史图和被替代图
```

## 如果卡片看起来像空白

这是 Obsidian Canvas 的正常行为：缩放比例太小时，卡片内容会被简化成几条横线。

可以这样处理：

1. 按住 `Ctrl` 并滚动鼠标放大。
2. 选中一组卡片后按 `Shift + 2` 聚焦到选中内容。
3. 按 `Shift + 1` 回到全局视图。

## 交给 Codex 继续整理

如果你直接修改 `.canvas` 文件，Codex 会先读：

```text
system/canvas-system.json
system/canvas-registry.json
system/canvas-view-graph.json
```

再根据 registry 判断哪张图是 current、哪张是 draft、哪张是 archive。

`.canvas` 文件主要给 Obsidian 和人读。稳定的父子关系、跳转关系和视图层级要同步到 `system/canvas-view-graph.json`，不要只留在画布卡片或连线里。
