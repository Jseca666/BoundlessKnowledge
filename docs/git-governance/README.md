# Git 治理模块

本文是人类薄入口。机器真相由以下文件接管：

```text
system/git-governance-system.json
system/git-governance-docs-map.json
scripts/validate-git-governance.ps1
scripts/git-governance-status.ps1
```

## 作用

Git 治理模块负责本项目的本地版本状态、远端地址、提交前检查、敏感信息边界和 GitHub 远端动作授权边界。

当前远端：

```text
https://github.com/Jseca666/BoundlessKnowledge.git
```

## 边界

- 可以做本地状态检查、提交计划、校验和版本边界维护。
- 不在没有明确授权时执行 push、release、issue、PR、merge、远端分支修改或凭据变更。
- 不把 Obsidian workspace、本地缓存、密钥、token、cookie、个人隐私材料纳入版本真相。

发布前完整清单见 `docs/technical/github-readiness.md`。
