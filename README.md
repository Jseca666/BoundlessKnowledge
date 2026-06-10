# 无界知识

这是一个面向长期演化的知识工程系统，用来把个人经验、论文、专业网页、GitHub 技术主题和 Codex 工作流连接成一个可检索、可追溯、可审查、可持续更新的知识网络底座。

根定位由 `system/project-ontology.json` 接管：无界知识不是单纯笔记仓库，也不是某个业务应用；它的目标是让知识从来源进入、被结构化、被验证、被检索、被 Codex 工作流调用，并持续回流闭环。

核心目标不是“存很多文件”，而是让每条知识都能回答四个问题：

- 它从哪里来？
- 它支持什么判断？
- 它和哪些概念、行业、工具、工作流有关？
- Codex 在具体项目里应该怎样安全、准确地调用它？

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `00-inbox/` | 原始输入暂存区：草稿、论文 PDF 摘要、网页摘录、GitHub 链接 |
| `10-sources/` | 来源记录：论文、仓库、网页、个人经验的可追溯元数据 |
| `20-notes/` | 原子知识：概念、方法、主张、经验规则 |
| `30-maps/` | 知识图谱视图：行业图、技术图、概念关系图 |
| `40-synthesis/` | 综合产物：主题简报、行业认知、技术雷达、实践手册 |
| `50-workflows/` | Codex 工作流包：如何把知识库接入具体项目 |
| `60-evals/` | 检索和认知质量评估用例 |
| `70-indexes/` | 自动生成或人工维护的索引 |
| `90-archive/` | 过期、合并、废弃材料 |
| `docs/` | 架构、采集流程、质量标准和集成说明 |
| `docs/technical/` | 本地设置、运维、校验、排障和未来 GitHub 发布准备 |
| `schemas/` | Markdown frontmatter 元数据约束 |
| `templates/` | 新知识条目的标准模板 |
| `scripts/` | 本地校验和索引脚本 |
| `system/` | 机器友好的路由登记、信息地图和系统开发原则 |

## 日常更新循环

1. 捕获：把未处理内容放进 `00-inbox/`，不要一开始就追求完美。
2. 建档：为来源创建 `10-sources/` 记录，标注出处、访问日期、可信度和主题。
3. 提炼：把可复用认知拆成 `20-notes/` 的原子笔记，每条只承载一个清晰判断。
4. 连接：在笔记中维护 `sources`、`related`、`domains`、`workflows` 等关系。
5. 综合：周期性沉淀到 `40-synthesis/` 和 `50-workflows/`。
6. 校验：运行脚本更新索引并检查元数据。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-index.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-kb.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
```

## 技术文档入口

本地设置、日常运维、校验、排障和未来 GitHub 发布准备从 `docs/technical/README.md` 进入；机器可读边界由 `system/technical-docs-map.json` 接管。

## 新建条目

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new-kb-item.ps1 -Type concept -Title "Retrieval Augmented Knowledge Base"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new-kb-item.ps1 -Type paper -Title "A Paper Title"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new-kb-item.ps1 -Type github -Title "A GitHub Topic Or Repository"
```

脚本会从 `templates/` 复制模板，生成标准 `id` 和文件名。
如果标题是中文，建议显式传入 ASCII slug：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new-kb-item.ps1 -Type concept -Title "检索增强知识库" -Slug "retrieval-augmented-kb"
```

## 给 Codex 使用

任何 Codex 项目需要调用本知识库时，优先读取：

1. `70-indexes/catalog.json`
2. 与任务相关的 `20-notes/`、`40-synthesis/`、`50-workflows/`
3. 对应 `10-sources/` 来源记录

在项目任务中可以这样要求 Codex：

> 先读取 `C:\Users\dzw\Documents\无界知识\70-indexes\catalog.json`，检索与本任务相关的知识条目。回答或修改代码时必须说明使用了哪些知识条目和来源记录。

## 基本原则

- 先证据，后观点。
- 每个事实尽量有来源记录。
- 原始材料和提炼后的知识分层存放。
- 避免把整篇版权内容复制进仓库；保存摘要、引用线索、链接和自己的分析。
- 私密信息、密钥、账号、未公开商业资料不进入 Git。
- 一个知识点只保留一个规范版本，其他文件通过链接引用它。
