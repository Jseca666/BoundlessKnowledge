# 知识摄入子系统

这是知识进入知识库的薄入口。机器真相由 `system/knowledge-ingestion-system.json` 和 `system/knowledge-ingestion-docs-map.json` 接管。

阅读顺序：

- `system/route-registry.json` route `knowledge-ingestion`
- `system/knowledge-ingestion-system.json`
- `system/knowledge-acquisition-system.json`
- `system/knowledge-ingestion-docs-map.json`
- `docs/knowledge-ingestion/acquisition.md`
- `docs/ingestion-workflow.md`
- `docs/source-quality.md`

边界：

- 本入口只说明去哪里读，不承载具体工作流细节。
- `00-inbox/`、`10-sources/`、`20-notes/` 等保存知识内容资产；知识摄入子系统负责治理进入方式、交接规则和质量门。
- Canvas 只做视觉入口，不作为系统行为真相来源。
