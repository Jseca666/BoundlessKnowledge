# Codex 集成方式

## 目标

让任意 Codex 项目都能把本仓库当成知识工程系统和领域认知底座，而不是每次从零调研。

Codex 工作流在本项目里有两层角色：一层用于搭建、维护和修复知识工程系统本身；另一层用于让知识捕获、分类、提炼、索引、检索、审查、诊断、loop 打磨和项目回流真正运行闭环。根定位见 `system/project-ontology.json`。

## 推荐调用顺序

1. 读取 `70-indexes/catalog.json`。
2. 根据任务关键词筛选候选条目。
3. 优先读取 `50-workflows/` 中相关工作流包。
4. 读取对应 `40-synthesis/` 和 `20-notes/`。
5. 对事实性判断回查 `10-sources/`。
6. 在最终方案中说明使用了哪些知识条目。

## 可复制给 Codex 的提示

```text
请把 C:\Users\dzw\Documents\无界知识 作为外部知识库。
先读取 70-indexes/catalog.json，找出与当前任务相关的知识条目。
使用知识条目时，请同时检查它们引用的 10-sources 来源记录。
涉及事实、行业判断、架构建议或安全建议时，说明所依据的条目 id。
如果知识库没有足够证据，请明确说缺口在哪里，不要补编来源。
```

## 工作流包格式

工作流包应该包含：

- 适用场景。
- 输入材料。
- 检索路径。
- 决策步骤。
- 输出格式。
- 质量门槛。
- 相关 source 和 note。

## 与向量库或 MCP 的关系

本仓库先保持文件系统可读、Git 可追踪。后续可以把 `70-indexes/catalog.json` 作为同步入口，将 Markdown 内容导入：

- 本地 SQLite FTS。
- 向量数据库。
- MCP memory graph。
- Supabase/PostgreSQL。
- 任意 RAG 服务。
