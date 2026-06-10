# 故障排查

本文是人类说明。复杂或可复发问题应进入诊断模块：

```text
.agents/skills/diagnostic-system/SKILL.md
system/diagnostics/diagnostic-system.json
system/diagnostics/issue-repair-queue.json
```

## 常见症状

| 症状 | 先看 |
| --- | --- |
| 路径不存在或校验找不到文件 | `system/route-registry.json`、`system/information-map.json` |
| Canvas 图和当前系统不一致 | `system/canvas-registry.json`、`system/canvas-view-graph.json` |
| 分类无法落到三级 | `30-maps/domains/domain-taxonomy.registry.json`、`domain-taxonomy-routing-guide.md` |
| loop 状态不清楚 | `system/loop-registry.json`、`system/loops/*/state.json` |
| 索引没有更新 | `scripts/build-index.ps1`、`70-indexes/catalog.json` |
| Markdown frontmatter 报错 | `schemas/kb-item.schema.json`、`templates/` |
| Canvas 或 JSON 出现连续问号占位符 | `scripts/validate-canvas.ps1`、`scripts/validate-system.ps1`、`system/tool-map.json` 的 UTF-8 写入策略 |
| PowerShell 输出中文像乱码，但编辑器里文件正常 | 先区分显示层和文件层：用 Node/UTF-8 字节检查确认文件内容，再检查 `[Console]::OutputEncoding`、`$OutputEncoding` 和 `chcp` |

## 编码排查

如果命令输出里看到“UTF-8 中文被按 GBK 显示后形成的异常字符组合”，不要先假定文件已经损坏。先做两步：

1. 文件层：用 UTF-8 读取并检查目标中文码点是否存在；如果文件能被 UTF-8 round-trip，且没有 replacement character、连续问号占位、私用区字符或典型 UTF-8/GBK mojibake 片段，文件内容通常是干净的。
2. 显示层：检查 PowerShell 版本、`[Console]::OutputEncoding`、`$OutputEncoding` 和 `chcp`。PowerShell 5.1、活动代码页 936 或 `$OutputEncoding = us-ascii` 都可能让终端输出看起来像乱码。

项目脚本默认设置 UTF-8 输出；如果手工读文件，优先使用能稳定处理 UTF-8 的工具，或在当前 PowerShell 会话先设置输出编码。

## 排查原则

1. 先冻结失败路径，说明哪个命令、哪个文件、哪个期望失败。
2. 从表面文件向上追溯到 route、registry、schema、tool 或 docs map。
3. 判断是局部修复还是系统升级。
4. 如果能复发，补机器登记或校验门。
5. 最后用 diagnosis acceptance 回答原问题是否真的解决。
