# GitHub 发布准备

本清单由 Git 治理模块接管：`system/git-governance-system.json` 决定机器边界，`docs/git-governance/README.md` 是人类入口。

本文是未来 GitHub 发布前的本地准备清单，不执行远程发布动作。

## 发布前必须检查

- 仓库里没有 API key、cookie、token、账号密码、个人隐私材料。
- README 能让外部读者理解项目目标、目录、运行方式和限制。
- 技术文档能说明本地设置、校验命令、故障排查和贡献边界。
- `.gitignore` 覆盖本地缓存、Obsidian 私有状态、临时文件和构建产物。
- 所有登记和索引校验通过。
- 许可证、公开范围、是否包含个人笔记和是否允许外部贡献已经由用户确认。

## 建议发布前命令

```powershell
git status --short
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-system.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-canvas.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-diagnostics.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-index.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-kb.ps1
```

## GitHub 公开前待定项

- 许可证类型。
- 是否保留中文为主，还是增加英文 README。
- 是否开放 issue、discussion、pull request。
- 是否加入 CI 自动跑校验脚本。
- 是否拆分个人知识内容和系统框架模板。

远程创建仓库、push、发布 release、打开 issue 或 PR 都属于外部动作，必须等用户明确授权。
