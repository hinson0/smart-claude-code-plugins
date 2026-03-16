# smart-claude-code-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 写完代码？直接说 **"发个PR"**，检查、提交、推送、PR 全自动搞定。
>
> 不想开 PR，只想 push？说 **"推一下"**。
>
> 只想 commit？说 **"提交"**。
>
> 也可以用斜杠命令：`/smart:pr`、`/smart:push`、`/smart:commit`。

一个为 Claude Code 设计的插件。代码写完之后，说一句话就行——它自动检查、提交、推送，并向 `main` 分支创建 Pull Request，无需任何额外操作。一句 `push`，自动拆分多 feature、生成 commit message 并推送，效果如下：

![demo](./assets/cn.png)

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

## 两种使用方式

**💬 直接说** — 在对话中自然表达：

- "commit" / "提交" / "完成了" → 智能提交
- "push" / "推一下" → check + commit + push
- "发个PR" / "create PR" → check + commit + push + PR

**⌨️ 斜杠命令** — 精确控制：

| 命令 | 作用 |
|---|---|
| `/smart:pr [目标分支]` | 完整流程：check → commit → push → PR（默认目标分支：`main`） |
| `/smart:push` | check → commit → push（不创建 PR） |
| `/smart:commit` | 仅提交（智能分组，自动生成 message） |
| `/smart:config` | 配置自动操作（每次任务后自动 commit/push） |

---

## 自动操作（Auto-Action）

想让 Claude 每次完成任务后自动提交或推送？配置一次即可：

```
/smart:config
```

可选项：
- **off** — 关闭（默认，仅手动操作）
- **commit** — 每次任务后自动 commit（仅本地）
- **push** — 每次任务后自动 commit + push

设置按项目存储在 `.claude/smart.local.md` 中，下次会话生效。

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

## 前置要求

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — 用于自动创建 GitHub remote 和 PR

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
