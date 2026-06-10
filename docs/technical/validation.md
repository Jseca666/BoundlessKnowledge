# 校验命令

本文是人类说明。工具机器登记在：

```text
system/tool-map.json
```

## 命令分工

| 命令 | 作用 |
| --- | --- |
| `scripts/validate-system.ps1` | 校验系统登记、路由、信息地图、Canvas registry、loop、docs map 和工具路径 |
| `scripts/validate-canvas.ps1` | 校验 Canvas JSON、注册关系、view graph、导航和布局协议 |
| `scripts/validate-diagnostics.ps1` | 校验诊断协议、issue queue、schema 和捕获路径 |
| `scripts/validate-reviews.ps1` | 校验审查协议、review queue、docs map、schema 和引用路径 |
| `scripts/audit-canvas-screenshot.ps1` | 为 current / active Canvas 生成 PNG 截图证据和机器报告 |
| `scripts/build-index.ps1` | 生成 `70-indexes/catalog.json` 和 `catalog.csv` |
| `scripts/validate-kb.ps1` | 校验知识 Markdown frontmatter 和 id |

## 推荐顺序

结构性系统改动：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-diagnostics.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-reviews.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-index.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-kb.ps1
```

Canvas 改动：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-canvas.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\audit-canvas-visual.ps1 -Strict
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\audit-canvas-screenshot.ps1 -Strict
```

知识条目改动：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-index.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-kb.ps1
```

## 解释口径

校验通过只说明登记和格式当前一致，不等于诊断接受。用户指出的问题仍要回到 failure packet 和 diagnosis acceptance 检查。
