# Canvas 视觉审美审查

本文是人类说明。机器真相在 `system/reviews/review-system.json`，可执行审查工具是 `scripts/audit-canvas-visual.ps1` 和 `scripts/audit-canvas-screenshot.ps1`。

## 定位

Canvas 视觉审美审查是 `review-system` 下的专门子能力，属于 `visual_review`。

它负责主动发现 current / active Canvas 图的人眼可读性问题：主流程边标签、节点间距、边标签净空、线条遮挡、导航与正文关系、主路径稳定性和视觉投影完整性。

颜色也属于审查对象。颜色必须是 view-scoped semantic language：系统图、分类图、loop 图和入口图可以使用不同 palette，但每张 current / active 图都要有 `color_semantics` 登记和可见 `color-legend`，不能让颜色只作为装饰或隐含状态。

它不替代诊断模块。若发现可复发的系统性缺陷，例如校验门缺失、绘制规则缺失、已有多张图同类失效，应把 finding handoff 给 `diagnostic-system`。

## 审查准则

- 主阅读路径是否只有一个主要方向。
- L0 入口图是否按登记的 `view_level`、`layer` 和 `primary_subject` 形成层级路由图，而不是主观混合栏目或普通文件预览堆。
- L0 入口卡片是否在打开子图前暴露 `L1` / `L2` 层级归属。
- 导航文件按钮是否低于人读说明卡片的视觉层级。
- 支撑文件是否用 `file-label-*` 作为一体化解读卡，并把文件节点压缩成嵌入式点击按钮。
- 主流程边是否默认无标签，流程语义是否写进编号卡片、标题、分区和空间顺序。
- 例外边标签是否被卡片、边框、文件节点或分区带遮挡。
- 线条是否穿过无关节点、导航标签或机器真相区。
- 右侧导航是否和正文保持清晰间距。
- 导航到正文的对应关系是否使用一个解释标签和一条直接线。
- 颜色是否有 view-scoped palette 登记，且图中有可见 `color-legend`。
- 分类图颜色是否只表达知识领域家族，没有被误读成系统状态。
- 系统/模块图颜色是否区分机器真相、治理方法、知识内容、来源输入、交接和诊断风险。
- 上下层指引线是否只表达导航/对应关系，没有混入 workflow 或 dataflow。
- 机器真相文件节点是否独立成区，不挤进主流程。
- `scripts/audit-canvas-visual.ps1 -Strict` 是否通过且 0 warning。
- 涉及用户可见布局、导航、颜色或可读性时，是否生成 `system/reviews/canvas-screenshots/latest-report.json` 和对应 PNG 截图证据。

## Handoff

```text
observation / risk -> 记录在 review queue，后续视觉调整时参考
defect + 可复发 -> 交给 diagnostics 做责任层修复
局部一张图的轻微美化 -> architecture-views 内直接修图并运行 visual audit
```

## 验收

Canvas 视觉审美审查通过，不等于 Canvas 机器登记正确。视觉审美审查之后仍需按影响面运行：

```text
scripts/validate-canvas.ps1
scripts/audit-canvas-visual.ps1 -Strict
scripts/audit-canvas-screenshot.ps1 -Strict
scripts/validate-reviews.ps1
```

## 2026-06-09 补充：颜色 token 审查

Canvas 颜色审查不只看“有没有图例”，还要看 token 是否稳定：
- 颜色 token 是否使用 Obsidian 预设 `1-6` 或 `#RRGGBB`。
- palette 的 role color 和 allowed_colors 是否也遵守同一规则。
- 当前图的颜色是否能从 `color-legend` 和 `system/canvas-registry.json` 找到一致解释。
- 命名色即使看起来语义清楚，也视为样式缺陷，因为不同环境渲染不稳定。

## 2026-06-09 补充：静态审查不是完整视觉接受

Canvas visual review 必须把两件事分开：
- 静态审查：JSON、registry、geometry、颜色 token、文本完整性和线路规则是否过关。
- 可见接受：这张图是否真的解决了用户看到的问题，尤其是 Obsidian 渲染后的层级、间距、缩放、图例和阅读路径。

如果只能做静态审查，要明确写出限制。用户指出校验后仍然严重不对时，review finding 必须 handoff 给 diagnostics，并要求诊断模块自审为什么漏掉上层原因。

## 2026-06-09 补充：截图级证据

截图级检查是 Canvas 视觉审查的关键步骤，补在几何审查之后、最终 finding 判断之前：

- `audit-canvas-visual` 负责结构和几何风险：重叠、线条穿越、标签净空、导航间距等。
- `audit-canvas-screenshot` 负责产出可打开的 PNG 证据和机器报告，证明当前登记图至少能被渲染成非空画面。
- 对 current / active Canvas 的布局、导航、颜色、可读性或用户可见问题做审查时，不能把截图检查当成可选项；除非明确记录当前环境无法生成截图证据。

当前截图工具从 `.canvas` JSON 生成本地 PNG，并不伪装成 Obsidian 原生截图。它的作用是补上“只看 JSON 不看图面”的证据层；如果后续接入真实 Obsidian 或浏览器渲染，审查模块再升级视觉 diff 和像素级比较。
