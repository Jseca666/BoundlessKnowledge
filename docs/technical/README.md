# 技术文档入口

本文只作为技术文档薄入口，不承载全部运维、校验或发布规则。机器真相和详细说明由路由文件接管。

## 先读顺序

1. `system/technical-docs-map.json`
2. `system/tool-map.json`
3. `system/route-registry.json`
4. `system/information-map.json`
5. 按当前任务进入 `docs/technical/*.md`

## 文档分工

- `docs/technical/setup.md`：本地环境、打开仓库、基础准备。
- `docs/technical/operations.md`：日常维护循环。
- `docs/technical/validation.md`：校验命令和运行顺序。
- `docs/technical/github-readiness.md`：未来 GitHub 发布前检查。
- `docs/technical/troubleshooting.md`：常见维护问题和诊断入口。

## 边界

- 技术文档只解释怎么运维，不作为系统行为真相。
- 系统行为以 `system/*.json`、`schemas/`、`scripts/` 为准。
- 远程发布、push、公开仓库、修改凭据等外部动作必须等用户明确授权。
- 新增长期技术文档前，先登记到 `system/technical-docs-map.json`。
