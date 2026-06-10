# Canvas 文件创建与放置规划

本文是人类说明。Canvas 的机器登记真相在：

```text
system/canvas-system.json
system/canvas-registry.json
system/canvas-view-graph.json
```

Canvas 子系统架构说明见：

```text
docs/canvas/architecture.md
```

## 基本原则

Canvas 是视觉架构系统，不是普通画图文件夹。它覆盖导航、系统架构、模块内部结构、workflow、dataflow、skill、schema、tool、loop、diagnostic、domain map 和 project context。后续 Canvas 会很多，所以每张图必须先判断用途，再放目录，再登记。

新增 Canvas 不直接放在 `30-maps/canvas/` 根目录。根目录只保留 README 和编号层级目录。

每张图也不是孤立图。稳定 Canvas 应该通过 Obsidian 文件节点形成父子导航：

- 系统总览图指向领域图、工作流图、工具图、项目图等下层图。
- 下层图放一个返回父图的 `.canvas` 文件节点。
- 平级图若经常一起使用，可以登记 `related_views`。
- 父子关系以 `system/canvas-registry.json` 为准，图上的文字说明只做辅助。

## 建图判断

稳定结构出现以下特征时，应考虑创建 Canvas：

- 一个模块有多个 owner 文件、输入输出、gate 或内部阶段。
- 一个 workflow 跨三个以上步骤、工具或状态。
- 一个 skill 不只是提示词，而是连接机器协议、queue、schema 或 validator。
- 一个 schema 或 registry 成为其他模块消费的契约。
- 一个 loop、诊断流程或队列有状态转换。
- 一个项目或 Codex workflow 会被反复调用。

临时想法可以先放 `80-drafts/`。一旦它开始作为结构入口被复用，就必须登记到 `system/canvas-registry.json` 和 `system/canvas-view-graph.json`。

## 数据分层

`.canvas` 是人读视觉文件；`system/canvas-view-graph.json` 是机器读图数据。

| 数据 | 主要读者 | 放什么 |
| --- | --- | --- |
| `system/canvas-registry.json` | 机器 | 视图登记、状态、目录、source_of_truth、生命周期 |
| `system/canvas-view-graph.json` | 机器 | 无坐标的 view 节点、父子边、导航边 |
| `30-maps/canvas/**/*.canvas` | 人类 / Obsidian | 坐标、卡片文字、视觉分组、文件节点 |
| `docs/canvas/*.md` | 人类 | 按专题拆分的使用说明、审查记录、设计解释 |

机器不应从 `.canvas` 的坐标、颜色、卡片文字中推断系统事实。稳定关系必须登记到 registry 和 view graph。

导航图和结构图也要分开：全局导航图只放“打开哪张图”的跳转线，文件节点只指向已登记的 `.canvas` 当前视图，不放 JSON、Markdown、脚本或 future placeholder。所有导航文件节点旁边都必须有中文目的标签，不能让用户靠被截断的文件名猜目的。所有 current / active 的非导航结构图，主体只放系统结构、模块关系、workflow、dataflow、taxonomy、状态转换或知识结构。若结构图需要快速跳到父图、子图或相关图，使用右侧独立纵向导航栏，导航线不能穿过主结构。结构图里的导航文件节点只做小型点击按钮，信息解释交给 `nav-label-*`；导航项若需要说明它对应当前图里的哪个模块，优先从这个 `nav-label-*` 直接拉一条 `bridge-*` 线到对应模块；这种关系只表示视觉对应，不表示数据流。

## 图层级、类别与边界

文件放置只回答“放在哪里”。一张图允许表达什么，由视图边界规则回答。

详细规则见：

```text
docs/canvas/view-boundaries.md
```

## 目录分层

Canvas 目录采用“编号层级 + 阅读顺序 + 模块子目录”，不是 `system/domain` 这种大桶。打开文件树时，应该能直接看出先读入口图，再读系统总览，再进入某个子系统下钻。

| 目录 | 用途 |
| --- | --- |
| `30-maps/canvas/00-entry/` | 最高层视觉入口图，只放默认导航入口 |
| `30-maps/canvas/10-system/` | 知识库系统自身的可视化总目录，不直接放零散模块图 |
| `30-maps/canvas/10-system/00-overview/` | 知识库操作系统自身架构、模块关系、数据流 |
| `30-maps/canvas/10-system/10-subsystems/` | 系统子模块下钻总目录，不直接放跨层级总览图 |
| `30-maps/canvas/10-system/10-subsystems/canvas-system/` | Canvas 子系统架构、目录布局、视觉治理 |
| `30-maps/canvas/10-system/10-subsystems/diagnostic-system/` | 诊断与系统修复模块图，表达 failure packet、证据链、责任修复层、校验和 diagnosis acceptance |
| `30-maps/canvas/10-system/10-subsystems/system-closure/` | 系统闭环、模块覆盖、成熟度、缺口和校验闭环图 |
| `30-maps/canvas/10-system/10-subsystems/{subsystem}/` | 其他系统子模块图，例如 skill、schema、tool、loop、dataflow、module internals |
| `30-maps/canvas/20-knowledge/` | 知识内容面，每个知识地图主题继续建子目录 |
| `30-maps/canvas/20-knowledge/10-domain-taxonomy/` | 领域 taxonomy、一级/二级/三级分类下钻图 |
| `30-maps/canvas/30-workflow/` | 入库、检索、Codex context pack、质量门、维护流程 |
| `30-maps/canvas/40-project/` | 具体项目相关的上下文图、项目架构图 |
| `30-maps/canvas/80-drafts/` | 未稳定草图、临时脑图、从 Obsidian 导入的待整理画布 |
| `30-maps/canvas/90-archive/` | 被替代但需要保留追溯的历史画布 |

## 命名规则

文件名使用 lowercase kebab-case。

```text
00-entry/kb-{topic}-overview.canvas
10-system/00-overview/kb-system-{view}.canvas
10-system/10-subsystems/{subsystem}/{subsystem}-{view}.canvas
20-knowledge/{topic}/{topic}-{view}.canvas
30-workflow/{workflow-name}/{workflow-name}-{view}.canvas
40-project/{project-name}/{project-name}-{view}.canvas
draft-{topic}-{yyyymmdd}.canvas
{original-name}-{yyyymmdd}.canvas
```

## 登记规则

每张可用 Canvas 都必须登记这些字段：

```json
{
  "id": "",
  "path": "",
  "status": "",
  "view_family": "",
  "view_type": "",
  "layer": "",
  "view_level": "",
  "view_category": "",
  "primary_subject": "",
  "boundary": "",
  "not_for": [],
  "purpose": "",
  "source_of_truth": [],
  "use_when": [],
  "parent_views": [],
  "child_views": [],
  "related_views": [],
  "navigation_nodes": []
}
```

`status=current` 的图表示某个 view_family 的默认可信入口。一个 view_family 最多只能有一张 current 图。

`navigation_nodes` 记录图上哪些文件节点负责跳到父图、子图或相关图。这样 Codex 和你都能知道图之间的实际导航关系。

同一关系还要同步到 `system/canvas-view-graph.json`，供机器无布局噪音地读取。

## 生命周期

1. 临时想法先放 `80-drafts/`，状态为 `draft`。
2. 稳定后移动到 `00-entry/`、`10-system/`、`20-knowledge/`、`30-workflow/` 或 `40-project/`。
3. 登记到 `system/canvas-registry.json`。
4. 如果它成为默认入口，把同 view_family 的旧 current 改为 `superseded` 或 `legacy-draft`。
5. 每次修改后运行 `scripts/validate-system.ps1`，并确认 `.canvas` 能被 JSON 解析。
6. 涉及 Canvas 文件、登记或 current view 时，同时运行 `scripts/validate-canvas.ps1`。
7. 涉及 Canvas 视觉布局或线路调整时，同时运行 `scripts/audit-canvas-visual.ps1 -Strict`。

## 线路放置

创建新 Canvas 时，先判断关系是否真的需要画线。Canvas 不是越多线越清楚，稳定图应优先保留高信号主线。

- 主流程、workflow、dataflow 和状态转换可以画线，但应短、直、方向一致。
- 导航跳转优先靠右侧导航栏、中文标签和小型 Obsidian 文件按钮表达，不强制用竖线串联。
- 机器真相文件节点优先成组摆放；如果连线会跨越分区横幅或主卡片，就不画。
- 分区标题到子卡片的层级关系优先由位置和标题表达，不要画大量扇形长线。
- 上下文对应关系默认使用一个 `nav-label-*` 解读标签和一条直接连到对应模块的 `bridge-*` 线，不再同时放正文 `content-marker-*` 形成重复解释。
- `context-route-*` 只作为例外服务视觉对应，不表示数据流、依赖或执行顺序。
- `context-rail-*`、`context-corridor-*`、`context-port-*` 只是机器路由点，必须近似不可见；不要把它们做成彩色文字小卡片，也不要让它们形成默认的导航布线路径。

## 判断口径

- 最高层入口：放 `00-entry/`
- 系统整体怎么运转：放 `10-system/00-overview/`
- 系统模块内部结构、skill、schema、tool、loop、diagnostic：放 `10-system/10-subsystems/{subsystem}/`
- 某个知识内容主题怎么分类或组织：放 `20-knowledge/{topic}/`
- 某个操作怎么执行：放 `30-workflow/{workflow-name}/`
- 某个项目怎么使用知识库：放 `40-project/{project-name}/`
- 还没想清楚：放 `80-drafts/`
- 已经被替代：放 `90-archive/`

## 已迁移的早期图

早期创建的系统图已经迁移到明确目录：

```text
30-maps/canvas/00-entry/kb-navigation-index.canvas
30-maps/canvas/10-system/00-overview/kb-system-architecture.canvas
30-maps/canvas/10-system/10-subsystems/diagnostic-system/diagnostic-system-architecture.canvas
30-maps/canvas/10-system/10-subsystems/canvas-system/canvas-system-architecture.canvas
30-maps/canvas/10-system/10-subsystems/canvas-system/canvas-directory-layout.canvas
30-maps/canvas/10-system/10-subsystems/system-closure/system-closure-architecture.canvas
30-maps/canvas/20-knowledge/10-domain-taxonomy/domain-taxonomy-overview.canvas
30-maps/canvas/90-archive/knowledge-base-architecture-detailed-draft-20260605.canvas
```

后续不应再在 `30-maps/canvas/` 根目录放 `.canvas` 文件。
