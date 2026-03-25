# smart-claude-code-plugins

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

## 特性

- **两阶段智能提交分组** — 第一阶段按 type 硬分割（feat vs fix vs refactor），第二阶段按目的对同类 type 进行语义分割。杜绝无关改动混入同一次提交。
- **Fail-Fast 管道** — 任意步骤失败立即停止，不会出现残缺推送或错误 PR。
- **自动 CI 检测** — 读取 `.github/workflows/*.yml`，在本地运行对应检查（ruff、pytest、eslint、tsc、jest、go test、turbo 等）。
- **自动创建 GitHub 仓库** — 未配置 remote？自动为你创建。
- **Conventional Commits** — 所有 commit message 自动遵循 `<type>(<scope>): <description>` 格式。
- **语言一致性** — PR 标题、摘要和测试计划自动与 commit message 使用相同语言。默认英文，可通过项目 `CLAUDE.md` 覆盖。
- **文件保护 Hook** — 阻止 Claude 编辑敏感文件（`.env`、lock 文件等）。通过项目级 `.claude/protect_files.jsonc` 配置，支持精确文件名匹配和 glob 模式（`*`、`**`）。
- **会话 Hook** — 会话开始时问候，结束时告别。
- **上下文分析 Agent** — 分析哪些插件占用了最多的上下文窗口，按大小排名展示表格和百分比。

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
| `/smart:check` | 仅运行本地 CI 检查（自动检测 workflow 配置） |

---

## 快速开始

**1. 安装插件**（强烈推荐）

先在 Claude Code 中注册插件市场：

```
/plugin marketplace add hinson0/smart-claude-code-plugins
```

然后从该市场安装插件：

```
/plugin install smart@smart-claude-code-plugins
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
    ├── 2. commit  — 两阶段语义分析：
    │                第一阶段：按 type 硬分割（feat/fix/refactor/...）
    │                第二阶段：同类 type 按目的再分割
    │                （自动生成 Conventional Commit message）
    │
    ├── 3. push    — 推送到 origin
    │                （未配置 remote 时自动在 GitHub 创建仓库并关联）
    │
    └── 4. pr      — 自动生成标题和正文，创建 Pull Request
                     （语言跟随步骤 2 的 commit message）
```

任意步骤失败均立即停止，不会执行后续操作。

---

## 文件保护

在项目根目录创建 `.claude/protect_files.jsonc`，阻止 Claude 编辑敏感文件：

```jsonc
// 受保护的文件列表 — Claude Code 不可编辑
// 不含通配符的为精确文件名匹配，含 * 或 ** 的走 glob 模式
[
  ".env",
  "package-lock.json",
  "pnpm-lock.yaml",
  "yarn.lock",
  "*.secret",
  "config/production/**"
]
```

**匹配规则：**
- 无通配符 → 精确文件名匹配（`.env` 会拦截 `.env` 但不影响 `.env.example`）
- `*` → 单层目录 glob 匹配（`*.lock` 匹配 `pnpm-lock.yaml`）
- `**` → 跨目录递归匹配（`config/production/**` 匹配 `config/production/db/secret.json`）

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
