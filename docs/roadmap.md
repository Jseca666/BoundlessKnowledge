# 路线图

## Phase 0: 仓库骨架

- 建立目录结构。
- 建立 frontmatter 标准。
- 建立模板。
- 建立索引和校验脚本。

## Phase 1: 手动高质量录入

- 每周整理个人草稿和项目经验。
- 每篇重要论文建立 source record。
- 每个高价值 GitHub 项目建立 source record。
- 建立第一批核心概念卡。

## Phase 2: 半自动采集

- 增加论文采集脚本。
- 增加 GitHub topic/repo 巡检脚本。
- 增加网页摘要和去重流程。
- 增加过期条目提醒。

## Phase 3: 检索增强

- 生成 SQLite/JSONL 索引。
- 增加 embedding 同步。
- 增加全文搜索。
- 增加按行业、任务、技术栈的检索入口。

## Phase 4: 知识图谱

- 将 `sources`、`related`、`domains`、`workflows` 转为图关系。
- 建立跨行业概念迁移图。
- 增加冲突知识和证据强度标记。

## Phase 5: Codex 项目工作流

- 为常见任务建立工作流包：调研、架构、编码、评审、测试、上线。
- 每个工作流包绑定检索路径和质量门槛。
- 为关键工作流建立 eval case。
