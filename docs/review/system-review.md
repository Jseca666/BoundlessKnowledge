# 系统内部审查

系统内部审查检查系统结构是否可被未来代理找到、理解、修改、校验和修复。

优先看这些面：

- `system/route-registry.json`
- `system/information-map.json`
- `system/system-closure-map.json`
- `system/module-governance-policy.json`
- `system/visual-coverage-map.json`
- `system/canvas-registry.json`
- `system/tool-map.json`
- 相关 schema、validator、docs map 和 Canvas 图

## 审查准则

- 模块是否登记到 information map。
- 路由是否声明 read、update 和 validation。
- 机器真相是否明确，Markdown 是否只做人类说明。
- 结构化记录是否有 schema 或契约。
- 校验脚本是否能发现漂移。
- 闭环总表是否记录 lifecycle、known gaps 和 next action。
- 稳定结构是否有可视化覆盖决策。
- 文档是否保持薄入口和路由分工。

发现明确缺陷时，交给 `diagnostic-system`。
