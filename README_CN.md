# smart-claude-code-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 写完代码，直接 `/smart:pr`，剩下的全帮你搞定。
>
> 什么？你不想开 PR，只想 push？没问题——`/smart:push`。
> 什么？push 也不要，就想 commit？也行——`/smart:commit`。
> 什么？你只想在提交前跑个检查确认没翻车？随你——`/smart:check`。

一个为 Claude Code 设计的插件。代码写完之后，你只需要运行一条命令——它自动检查、提交、推送，并向 `main` 分支创建 Pull Request，无需任何额外操作。

---

## 快速开始

**1. 安装插件**（强烈推荐）

先在 Claude Code 中注册插件市场：

```
/plugin marketplace add hinson0/smart-claude-code-plugin
```

然后从该市场安装插件：

```
/plugin install smart@smart-claude-code-plugin
```

**2. 登录 GitHub CLI** _（仅需一次）_

```bash
gh auth login
```

**3. 完成。在任意仓库中运行：**

```
/smart:pr
```

它会自动完成：检测 CI 配置并在本地运行检查 → 智能提交 → 推送 → 在 GitHub 上创建 PR。

---

## 工作原理

```
/smart:pr
    │
    ├── 1. check   — 读取 .github/workflows/*.yml，运行对应本地检查
    │                （ruff/pytest、eslint/tsc、go test，无 CI 配置则跳过）
    │
    ├── 2. commit  — 语义分析改动，自动生成 commit message
    │                （多个独立 feature 时自动拆分为多次提交）
    │
    ├── 3. push    — 推送到 origin
    │                （未配置 remote 时自动在 GitHub 创建仓库并关联）
    │
    └── 4. pr      — 自动生成标题和正文，创建 Pull Request
```

任意步骤失败均立即停止，不会执行后续操作。

---

## 全部命令

| 命令 | 作用 |
|---|---|
| `/smart:pr [目标分支]` | 完整流程：check → commit → push → PR（默认目标分支：`main`） |
| `/smart:push` | check → commit → push（不创建 PR） |
| `/smart:commit` | 仅提交（智能分组，自动生成 message） |
| `/smart:check` | 仅运行 CI 配置推断出的本地检查 |

---

## 前置要求

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — 用于自动创建 GitHub remote 和 PR

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
