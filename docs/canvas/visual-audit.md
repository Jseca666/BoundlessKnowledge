# Canvas 视觉审查记录

本文是人类说明。可执行登记与规则以 `system/canvas-registry.json` 为准。

## 2026-06-06 审查结论

早期 Canvas 文件没有节点重叠，主要问题不是 JSON 错误，而是视觉职责过载：

- 系统总览图同时承担主流程、状态、机器真相、下钻入口，导致阅读路径不够稳定。
- 文件节点散在各处，Obsidian 可点击能力没有形成固定导航区。
- 领域分类图与系统图的视觉语言接近，容易让人误以为它们属于同一层级。
- Canvas 子系统图和目录布局图过于横向铺开，视线移动距离偏长。
- 导航线和架构数据流线混在同一张入口图里，导致线的语义不明显。

本轮已把全局导航入口和知识库系统架构图拆成不同视图；同时把“左侧主结构、右侧纵向导航栏、导航线不穿过主结构”升级为所有 current / active 非导航结构图的通用规则，而不是某一张图的局部调整。

后续诊断指出：只升级规则和说明不够，必须同步迁移现有 `.canvas` 资产并补校验门。因此本轮继续完成：

- `canvas-directory-layout-map` 的返回父图节点迁移到右侧导航栏。
- `domain-taxonomy-overview-map` 的返回导航入口迁移到右侧导航栏。
- `scripts/validate-canvas.ps1` 增加 current / active 非导航结构图的右侧导航节点检查。
- `kb-navigation-index` 收紧为纯 L0 跳转索引：不再放机器真相文件节点、future placeholder 或非导航边。
- `scripts/validate-canvas.ps1` 增加 L0 入口图纯导航检查，以及所有 current / active 图的可见 `.canvas` 文件节点登记检查。
- 本轮进一步给所有 current / active 图的导航文件节点增加中文目的标签，并由 `scripts/validate-canvas.ps1` 检查 `nav-label-{node_id}`。
- 本轮新增 `bridge-*` 上下文连接线，用“对应：...”标签把右侧 `nav-label-*` 直接连到当前图里的对应内容节点，并由 validator / visual audit 区分它与主流程/dataflow。
- 后续进一步把结构图右侧导航文件节点缩成小按钮：按钮只负责点击跳转，目的说明和当前内容对应都由 `nav-label-*` 这一处解释承担。
- 新增 `scripts/audit-canvas-visual.ps1` 作为视觉审美检查，专门检查空白卡片、节点重叠、锚点拥挤、超长线等人眼可读性问题；`validate-canvas.ps1` 仍负责结构和登记正确性。

## 调整原则

稳定 Canvas 采用固定视觉分区：

```text
标题区
主路径区
下钻或返回区
状态 / 规则区
机器真相区
```

## 2026-06-06 线路摆放升级

这次审查进一步确认：线条不是附属装饰，而是 Canvas 的一级布局对象。即使边的语义正确，只要它穿过非端点卡片、横向分区带、导航标签或文件节点，用户看到的就是遮挡和混乱。

因此 `scripts/audit-canvas-visual.ps1` 已升级为几何审查：按 `fromSide` / `toSide` 计算边的实际端点，检查线段是否穿过任何非端点节点；同时在严格模式下把长斜线作为视觉风险处理。

现有 current / active 图已做资产迁移：
- 去掉 L0 入口图和右侧导航栏中穿过 `nav-label-*` 的串联线。
- 去掉底部或顶部文件节点拉向主卡片的低价值长引用线。
- 去掉从分区标题向多张子卡片发散的长斜线，改由分区、位置和标签表达分组。
- 保留主流程的短线、必要的状态线，以及从右侧 `nav-label-*` 到对应模块的直接上下文解释线。

后续规则：
- 线必须服务阅读路径，不能为了“看起来有关系”而到处连。
- 能用空间分组、颜色、标题、标签表达的关系，不优先画线。
- 机器真相文件节点可以成组摆放，不必都向主卡片拉线。
- Canvas 视觉修改后必须运行 `scripts/audit-canvas-visual.ps1 -Strict`，0 warning 才算视觉接受。

## 2026-06-06 导航到当前内容的单解读线

进一步审查发现，上一轮把右侧导航关系停在 `bridge-anchor-*` 锚点上，虽然避免了长线遮挡，但用户仍然看不出导航项最终对应当前图里的哪个真实内容节点。

后续用户反馈进一步指出：如果右侧已经有导航解读，正文再放 `content-marker-*` 就变成两套重复解释，结构会显得呆。因此当前默认视觉语法改为“一个解读 + 一条线”：
- `nav-label-*` 是唯一的人读解释。
- 小型 `.canvas` 文件节点只负责点击跳转。
- `bridge-*` 从 `nav-label-*` 直接连到当前层面的真实内容节点。
- `bridge-anchor-*`、`content-marker-*` 和 `context-route-*` 退回为例外方案；如果出现，应能解释为什么一条直接线不够清楚。

当前系统架构图中的对应关系：
- 领域分类导航由 `nav-label-domain-taxonomy-canvas-file` 直接对应 `stage-domain`。
- Canvas 子系统导航由 `nav-label-canvas-system-canvas-file` 直接对应 `stage-index`。
- Canvas 目录导航由 `nav-label-canvas-directory-layout-canvas-file` 直接对应 `machine-truth-band`。
- 诊断系统导航由 `nav-label-diagnostic-system-canvas-file` 直接对应 `status-band`。
- 系统闭环导航由 `nav-label-system-closure-canvas-file` 直接对应 `feedback-note`。

具体口径：

- 一个 current view 只保留一个主阅读方向。
- 上层图负责概览，下层图负责细节。
- 下钻文件节点靠近被展开的模块。
- 返回父图的文件节点放在顶部或左上方。
- 机器真相文件统一放到底部或顶部资料带，不混入主流程。
- 不用大量长斜线连接静态文件，避免视觉噪音。
- 导航入口图只表达跳转关系；所有 current / active 的非导航结构图，主体只表达系统结构、模块关系、workflow、dataflow、taxonomy、状态转换或知识结构。只要图内需要父图、子图或相关图跳转入口，就统一放在右侧独立纵向导航栏，不让导航线穿过主结构。
- L0 入口图的文件节点只能指向已登记 `.canvas` 视图，不放机器真相文件、未来占位目标或非导航关系边。
- 任何 current / active 图上只要出现指向已登记 Canvas 视图的文件节点，都必须同步登记到 `navigation_nodes`。
- 任何导航文件节点旁边都要有中文目的标签；文件名和缩略预览不能承担导航说明。
- 导航栏与主内容的关系默认用 `nav-label-*` 到真实内容节点的一条直接 `bridge-*` 线表达，不能替代主流程、dataflow 或 workflow 边；`bridge-anchor-*`、`content-marker-*` 和长距离 `context-route-*` 只作为例外。
- 非导航结构图里的导航文件节点必须保持小按钮形态；如果 Obsidian 文件预览卡过大，就会抢走信息层级，应该缩小并让文字标签解释目的。
- 模块内部图必须把 trigger/input、核心步骤、owner 文件、机器真相、校验和导航分区表达清楚。
- workflow/dataflow 图必须让方向、状态转换和质量门一眼可见。
- skill/schema/tool/loop/diagnostic 图必须区分薄入口、机器协议、状态文件、校验工具和人读说明。
- 全局视觉规则变更后，必须枚举受影响的 current / active 图，迁移现有资产或登记例外；不能只更新 policy、registry 或 docs。
- 每次 current / active Canvas 视觉修改后，除了 `validate-canvas.ps1`，还要运行 `scripts/audit-canvas-visual.ps1`。

## 本次调整范围

- `30-maps/canvas/00-entry/kb-navigation-index.canvas`
- `30-maps/canvas/10-system/00-overview/kb-system-architecture.canvas`
- `30-maps/canvas/20-knowledge/10-domain-taxonomy/domain-taxonomy-overview.canvas`
- `30-maps/canvas/10-system/10-subsystems/canvas-system/canvas-system-architecture.canvas`
- `30-maps/canvas/10-system/10-subsystems/canvas-system/canvas-directory-layout.canvas`
- `30-maps/canvas/10-system/10-subsystems/diagnostic-system/diagnostic-system-architecture.canvas`
- `30-maps/canvas/10-system/10-subsystems/system-closure/system-closure-architecture.canvas`

## 当前视图结构

```text
视觉导航入口（L0）
  -> 知识库系统架构图（L1 系统总览）
  -> 领域分类层级图（L1 知识内容）
  -> Canvas 子系统架构图（L2 可视化系统）
       -> Canvas 目录布局图（L4 目录边界）
  -> 审查模块图（L2 治理子系统）
  -> 诊断与系统修复图（L2 治理子系统）
  -> 系统闭环治理图（L2 治理子系统）
```

## 2026-06-07 诊断契约可视化同步

用户指出：诊断契约升级已经更新了规则、schema、validator、skill 和 issue 队列，但对应 Canvas 图没有同步更新，系统仍然没有闭环。

本次修复范围：

- 更新 `diagnostic-system-architecture.canvas`，把旧的 `positive_rule / forbidden_pattern / quality_gate` 固定模型改成 `positive_model_repair / constraint_decision` 主模型。
- 在诊断图中新增“可视化投影同步”节点，明确 system upgrade 需要检查 dedicated / shared Canvas 覆盖。
- 更新 `system/diagnostics/diagnostic-system.json`，把 `sync-visual-projection` 纳入诊断流程。
- 更新 `system/canvas-registry.json`、`system/visual-coverage-map.json` 和 `system/system-closure-map.json` 的相关登记，说明本次可视化投影已补齐。

验收口径：规则、机器契约、诊断记录、Canvas 视图和视觉审查都要同步通过，不能只用 validator 通过来代表系统闭环。

## 2026-06-07 文本完整性修复

用户截图指出 Canvas 图中出现连续问号占位符。诊断确认这不是 Obsidian 渲染问题，而是 `.canvas` 和少量系统 JSON 文件里的文本已经被写坏。

本次修复范围：

- 修复 Canvas 子系统图、系统闭环图、领域分类总览图、三级分类矩阵图中的不可读占位文本。
- 修复 `system/development-principles.json` 和 `system/canvas-registry.json` 中的污染字段。
- `scripts/validate-canvas.ps1` 增加 Canvas 节点文本和边标签的文本完整性检查。
- `scripts/validate-system.ps1` 增加系统、schema、领域 JSON 字符串的文本完整性检查。

验收口径：可信 Canvas 和系统 JSON 不能含连续问号占位符、Unicode replacement character 或典型 CJK 编码乱码标记。视觉结构正确但文本不可读，也不能算视觉接受。

## 2026-06-07 边标签净空审查

用户截图指出系统闭环图中两个单元之间的连线文字被卡片遮挡。诊断确认这不是 JSON 结构错误，而是视觉审查只看线段交叉，没有把边标签本身当作一等布局对象。

本次修复范围：

- `scripts/audit-canvas-visual.ps1` 增加横向边标签净空检查。
- 拉开诊断图、系统闭环图、审查图的主流程节点间距。
- 将 `Canvas 视觉审美审查` 登记为 `review-system` 下的专门子能力。
- 新增 `docs/review/canvas-visual-aesthetic-review.md` 作为人读说明。

验收口径：current / active Canvas 图只要边标签被挤进小于标签宽度的卡片间隙，`scripts/audit-canvas-visual.ps1 -Strict` 就不能通过。

## 2026-06-07 主流程边标签禁用

后续用户截图继续显示：即使脚本估算的边标签净空足够，Obsidian 实际渲染仍可能让主流程边标签被相邻卡片覆盖。因此“拉大间距”不是稳定方案。

新的稳定口径：

- current / active 结构图的主流程边默认不写 label。
- 流程语义放进编号卡片、标题、分区、局部说明和空间顺序。
- `bridge-*` 的“对应：...”标签保留，用于右侧导航到当前内容的解释线。
- `scripts/audit-canvas-visual.ps1 -Strict` 会把非 `bridge-*` 主流程边标签作为视觉风险处理。

本次已迁移所有 current / active Canvas：非 `bridge-*` 主流程边标签已删除，视觉审查 0 warning。

## 2026-06-07 入口图审美刷新

用户指出 entry 图的设计审美一般。审查确认它不是登记错误，也不是系统性故障；问题在于 L0 入口虽然合规，但视觉上仍像大文件预览列表，缺少入口选择器的层级感。

本次调整：

- 将 `kb-navigation-index.canvas` 改为紧凑入口卡片：人读说明由 `nav-label-*` 承担，`.canvas` 文件节点缩小为 Obsidian 点击按钮。
- 移除入口图连线，避免 L0 入口被误读成结构图或流程图。
- 将“L0 入口图应有明确入口层级”加入 Canvas 规则和视觉审查准则。

验收口径：L0 入口只做跳转，但仍要有明确视觉层级。它应该帮助用户快速决定打开哪张图，而不是展示一组同等重量的文件预览卡。

## 2026-06-07 入口图层级归属修复

用户进一步指出：问题已经不是格式，而是内容层级归属、整理和关联关系。诊断确认上一轮“理解系统 / 治理质量”的两列分组仍然是主观栏目，会把 `L1 system-overview`、`L1 knowledge-content` 和多个 `L2 system-subsystem` 混在一起。

新的稳定口径：

- L0 入口图是层级路由图，不是普通按钮面板。
- 入口分组必须服从 `canvas-registry` / `canvas-view-graph` 中登记的 `view_level`、`layer` 和 `primary_subject`。
- 当前入口按主线入口、知识内容层、可视化系统层、治理闭环层组织。
- 每个 `nav-label-*` 必须暴露目标图的 `L1` / `L2` 层级，让用户在打开前知道它是总览、知识内容还是子系统。
- 更细的归属分组由 Canvas 视觉审美审查判断；机器校验只检查可稳定判断的 `view_level` 暴露。

验收口径：入口图不能只“好看”和“可点击”。它必须让用户一眼看出当前 Canvas 网络的上层层级归属。

## 2026-06-07 模块分层模型补齐

后续诊断确认：入口图层级问题不是单张图问题，而是系统内部同时存在多套分层口径。`information-map` 记录模块边界，`system-closure-map` 记录 `owner_layer`，Canvas 记录 `view_level / layer`，但此前没有一个统一机器真相说明“模块职责归属”。

本次新增：

- `system/module-layer-model.json`：稳定模块 `owner_layer` 和 `module_kind` 的机器真相。
- `information-map` 模块条目增加 `owner_layer` / `module_kind`。
- `system-closure-map` 的 `owner_layer` 必须与分层模型一致。
- `validate-system.ps1` 增加分层一致性检查。
- 系统总览图底部机器真相区加入 module-layer-model 支撑文件。

验收口径：目录位置、Canvas `view_level`、生命周期和模块职责归属是四条轴。任何新增模块都必须先在分层模型里定职责归属，再登记到信息地图、闭环总表和可视化系统。

## 2026-06-07 支撑文件解读卡

用户截图指出部分文件块只有文件名称，没有解释该文件在当前图里的作用。诊断确认：此前规则只强制导航文件节点有 `nav-label-*`，但没有要求机器真相区、支撑文件区的非导航文件节点也有解读。

本次调整：

- 将 current / active Canvas 图中的非导航支撑文件改成一体化卡片：`file-label-*` 是可读主体，文件节点缩成嵌入式点击按钮。
- 文件节点继续负责 Obsidian 点击打开；卡片内部文字负责告诉人这个文件在当前图中的角色。
- `scripts/audit-canvas-visual.ps1 -Strict` 会提示缺少 `file-label-*` 的支撑文件节点。

验收口径：文件名不是解读。current / active 图里的支撑文件必须让用户不用打开文件，也能知道它是 registry、schema、validator、状态、索引、workflow 还是人读说明。

## 2026-06-10 支撑关系机器登记

对比 OR 项目的可视化系统后，本项目吸收其“图背后有机器关系登记”的设计，但不照搬密集连线。当前规则升级为 registry-first：

- `file-label-*` 继续承担人眼可读的文件角色说明。
- `support_bindings` 记录每个支撑文件卡片向上支撑哪个模块、流程、状态、gate 或边界节点。
- `support_relations` 记录支撑文件之间的关系链，例如 policy -> registry -> validator。
- 可见连线只在确实改善阅读时才画；如果画了，再用 `visual_edge_id` 绑定到登记关系。
- `scripts/validate-canvas.ps1` 和 `scripts/audit-canvas-visual.ps1 -Strict` 会检查 current / active 非导航图是否遗漏支撑绑定。

验收口径：底部机器真相区不能只是“文件参考书目”。每个支撑文件都要能被 agent 追溯到当前图的上层结构含义，同时不把图面重新变成线路噪音。

## 2026-06-07 入口图父子层级修复

用户指出：Canvas 子系统显然属于系统内容的一部分，不应该在入口图中和“系统总览”并列。诊断确认问题不只是排版，而是 L0 入口图和 view graph 把 L2 system-subsystem 快捷入口误当成了 L0 的真实 child。

修复口径：

- L0 总入口只把 L1 主干视图登记为 child：系统总览、知识领域分类。
- Canvas、诊断、审查、闭环、系统结构治理是 L2 系统子系统，canonical parent 改为 L1 系统总览。
- L0 可以保留 L2 快捷按钮，但必须视觉嵌套在“系统总览下钻”区域，不能和系统总览并列。
- L2 子系统图的返回入口改为“返回：系统总览”，不再直接把总导航入口当父图。
- validate-canvas 增加父子层级校验，避免 shortcut-as-parent 再次出现。

验收口径：入口图要体现 `L0 -> L1 主干 -> L2 子系统`，方便点击不能覆盖结构归属。

## 2026-06-08 颜色语义与层级指引参考迁移

用户指出 `C:\Users\dzw\Desktop\or` 项目的 Canvas 可视化系统中，不同颜色方块和上下层连线指引关系值得学习。审查确认可迁移的是方法，不是 OR 项目的内容：颜色要成为受治理的视觉语言，层级指引要和主数据流分开。

本次采用的口径：

- 颜色语义按视图类型分域：系统/模块图使用系统角色色板，分类图使用知识领域家族色板，loop 图使用 loop 状态色板，入口图使用层级导航色板。
- 每张 current / active 图都必须在 `system/canvas-registry.json` 声明 `color_semantics`，并在 `.canvas` 里显示 `color-legend`。
- 分类图里的颜色只解释一级知识领域家族，不能被读成系统状态；系统图里的颜色也不能反过来替代领域分类。
- 上下层指引由 `navigation_nodes`、`canvas-view-graph` 和少量 `bridge-*` 对应线承担；这些线不替代 workflow、dataflow 或机器真相。
- `scripts/validate-canvas.ps1` 检查 palette、图例和颜色是否越界；`scripts/audit-canvas-visual.ps1 -Strict` 检查图例是否足够可读。

验收口径：以后新增或升级 Canvas，不允许只有“好看的颜色”。颜色必须能从当前图的图例读懂，并能从 registry 找到对应 palette。

## 2026-06-09 Loop 图颜色 token 修复

用户指出 loop 模块图样式不对。审查后确认，问题不是 loop 机制本身，而是颜色语义刚升级后只检查了“颜色是否属于 palette”，没有检查“palette token 是否是 Obsidian 稳定颜色”。

本次修复：
- `loop-orchestration-architecture.canvas` 从 `purple/cyan/red/yellow/green/orange` 迁移到 Obsidian 预设色 `1-6`。
- `kb-system-architecture.canvas` 中残留的 `cyan` shortcut 色同步迁移。
- `system/canvas-registry.json` 的 `loop_state_palette_v1` 和 `system_role_palette_v1` 不再允许命名色。
- `scripts/validate-canvas.ps1` 增加 palette role、allowed_colors、node color、edge color 的稳定 token 检查。

验收口径：current / active Canvas 图里的颜色可以有语义差异，但必须使用稳定 token：`1-6` 或 `#RRGGBB`。英文命名色不再作为受治理 palette token。

## 2026-06-09 静态校验与可见接受边界

用户进一步指出：loop 图样式问题不是小瑕疵，而是严重系统问题。诊断后确认，严重性不在颜色本身，而在接受模型：系统容易把 `validate-canvas`、`audit-canvas-visual -Strict` 和文本完整性通过，当成 Canvas 已经对用户可见地可靠。

新的口径：
- 静态校验是必要证据，不是完整视觉接受。
- current / active Canvas 视觉修复必须回到原始可见故障：样式、层级、线路、图例、文字是否真的解决。
- 如果当前运行无法检查 Obsidian 实际渲染截图，必须在诊断或最终说明里写明限制，不能假装 validator 已经证明了全部视觉体验。
- 如果用户在校验通过后仍指出图面、结构或路线严重不对，诊断模块本身要触发 self-audit。

## 2026-06-09 截图级视觉检查

用户要求可视化系统具备截图级视觉检查。诊断确认：几何审查能发现节点重叠、长线、边穿卡片等问题，但它仍然不是“看到图面”的证据。

本次新增：

- `scripts/audit-canvas-screenshot.ps1`：从已登记的 current / active Canvas 生成 PNG 视觉快照。
- `system/reviews/canvas-screenshots/latest-report.json`：记录本轮渲染范围、截图路径、非空像素比例、错误和 warning。
- `system/reviews/canvas-screenshots/*.png`：供人工打开查看的截图证据。

使用口径：

- 截图证据是审查证据，不是 Canvas 机器真相；机器真相仍在 `system/canvas-registry.json` 和 `system/canvas-view-graph.json`。
- current / active Canvas 如果涉及布局、导航、颜色、可读性或用户可见问题，除了 `validate-canvas` 和 `audit-canvas-visual`，还要运行截图检查；它是视觉审查关键步骤，不是可选产物。
- 当前版本使用本地 `System.Drawing` 从 `.canvas` JSON 渲染 PNG，不等同于 Obsidian 原生渲染；如果未来接入 Obsidian 或浏览器自动化，再升级为真实渲染截图/视觉 diff。

命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\audit-canvas-screenshot.ps1 -Strict
```
