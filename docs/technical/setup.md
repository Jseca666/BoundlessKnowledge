# 本地设置

本文是人类说明。机器真相在：

```text
system/technical-docs-map.json
system/tool-map.json
system/route-registry.json
system/information-map.json
```

## 本地打开

当前仓库位置：

```text
C:\Users\dzw\Documents\无界知识
```

Obsidian 可以直接把这个目录作为 vault 打开。视觉入口是：

```text
30-maps/canvas/00-entry/kb-navigation-index.canvas
```

## 需要的基础能力

- PowerShell：当前校验脚本和索引脚本的薄入口。
- Obsidian：查看和编辑 `.canvas` 视觉结构。
- Codex：读取 route、information map、catalog 和相关模块文件。
- Git：未来发布 GitHub 前用于 diff、commit、tag 和远程同步。

## 初次检查

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-canvas.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-diagnostics.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-index.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-kb.ps1
```

如果任何一步失败，先走诊断模块，不要直接局部改文件。
