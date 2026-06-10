# 日常运维

本文是人类说明。运维命令登记在 `system/tool-map.json`。

## 日常循环

1. 进入仓库根目录。
2. 先读 `system/route-registry.json` 判断任务归属。
3. 修改对应模块，而不是只改表面文件。
4. 同步受影响的 route、information map、docs map、Canvas、schema、loop、tool map 或索引。
5. 运行相关校验。
6. 如果是可复发问题，登记到 `system/diagnostics/issue-repair-queue.json`。

## 常规维护命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-index.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-kb.ps1
```

涉及 Canvas 时加跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-canvas.ps1
```

涉及诊断模块时加跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-diagnostics.ps1
```

## 运维口径

- 不要把私密信息、密钥、账号、cookie、token 写入仓库。
- 不要把远程发布动作混入本地整理；GitHub 发布必须单独确认。
- 不要把生成物当唯一真相；生成物要能由脚本或登记追溯。
- 重要模块一旦增长，优先补 docs map，而不是扩写入口文档。
