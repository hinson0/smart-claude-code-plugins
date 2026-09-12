# smart-codex-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md)

</div>

> 写完代码？在 Claude Code 运行 **`/smart:commit`**，或在 Codex 运行 **`$smart:commit`**。

这是一个同时支持 **Claude Code** 与 **Codex** 的插件，提供聚焦的开发工作流、内容工具、会话工具和工程规则。

---

## 快速开始

插件**同时内置两套清单**（`.claude-plugin/` 给 Claude Code，`.codex-plugin/` 给 Codex），在任一宿主里都能原生安装。按你的宿主选择：

### Claude Code

添加市场，然后安装插件——在 Claude Code 内执行：

```
/plugin marketplace add hinson0/smart-claude-code-plugins
/plugin install smart@smart
```

> 已经本地克隆了？把市场指向你的克隆目录即可：`/plugin marketplace add /path/to/smart-claude-code-plugins`。安装后重启会话，让 skills、hooks 和 statusline 生效。

### Codex

最友好的方式是在 Codex session 内直接添加，无需克隆：

1. 运行 `/plugins`
2. 选择 **[Add Marketplace]**
3. 粘贴来源——`hinson0/smart-claude-code-plugins`（owner/repo）或完整 git URL——回车确认
4. 打开 **Smart** 市场，安装 **smart** 插件

> 喜欢命令行？它会直接从 Git 拉取，无需克隆：
>
> ```bash
> codex plugin marketplace add hinson0/smart-claude-code-plugins
> codex plugin add smart@smart
> ```

---

## 本 Marketplace 的插件

本仓库发布一个同时支持 Claude Code 与 Codex 的插件：

| 插件 | 安装名 | 用途 |
|------|--------|------|
| Smart | `smart@smart` | 开发工作流、HTML/PDF/Wiki 工具、周报和会话工具 |

Claude Code 使用 `/smart:*`；Codex 提供对应的 `$smart:*` skills。

```bash
# Claude Code：添加 marketplace 后执行
/plugin install smart@smart

# Codex：添加 marketplace 后执行
codex plugin add smart@smart
```

Smart 包含十五个 skills：`clean-branches`、`close-issue`、`code-simplifier`、`commit`、
`generate-wiki`、`github-skills-pdf`、`help`、`hud`、`learning`、`local`、
`matt-implement-all-tickets`、`my-weekly`、`one-by-one`、`pair-write`、`pr`。
部分流程依赖 Git、`gh`、`glab`、Node.js、Python/PDF 工具、
浏览器或文档能力；每个 skill 都会检查自己的前置条件。
所有 skill 都只由用户主动调用：请明确使用对应的 `/smart:*` 或
`$smart:*` 名称，不依赖模型自动调用。
Codex 界面统一显示 `smart:<name>`，保留 Claude Code 原调用名但省略 `/`，不再使用另一套标题。

---

## 特性

**Smart Commit**

- **低成本执行** — Claude Code 使用 Haiku；Codex 把完整提交工作流交给一个低 reasoning 的 GPT-5.6 Luna worker，并允许一次默认子 agent 兜底。
- **语义分组** — type 是硬边界，purpose 是软边界，独立改动必须成为独立提交。
- **仓库感知 message** — 依次遵循项目规则、近期 Git 历史和 Conventional Commits。
- **仅提交** — 不执行 CI 检查、版本修改、push 或创建 PR。

**保护与自动化**

- **会话 Hook** — 会话开始时问候（通过 macOS `say` TTS 语音播报）。
- **会话日志** — 每次工具调用的完整输入数据均记录到 `.smart/session-logs/`，便于事后调试和审计。
- **串行 Ticket 交付** — `/smart:matt-implement-all-tickets` 与 Matt `/implement` 一起显式加载后，用一个编排 session 驱动全新 workers，逐张实现、验证、记录并关闭当前 `/to-tickets` 输出。支持已配置的 GitHub、GitLab 和本地 Markdown tracker，并在首个未完成收口处停止。
- **可审计的 GitLab Issue 收口** — `/implement` 完成提交与 Review 后，`/smart:close-issue` 会核对当前分支上的实现 commit、验收证据和 Review 结论。明确授权关闭后，它先发布这些开发资产、再关闭 Issue；目标分支是否集成只披露，不作为关闭门禁。仅使用 `glab`，不会推导出 push、merge、创建 MR/PR、修改 checklist 或标签的权限。

**实用工具**

- **HUD / Statusline 安装器** — 一条命令安装功能丰富的状态栏，显示模型、Git 分支、上下文用量、速率限制、系统资源和工具调用统计。提供两个安装级别（简化版 / 完整版）及从备份恢复，仅 user 作用域。
- **帮助概览** — `/smart:help` 动态扫描并列出所有技能、hook 和 agent 及其描述。
- **全新上下文代码简化** — `/smart:code-simplifier` 把完整流程交给一个串行、不可递归委派且不带对话历史的 worker。主 agent 不接触目标代码；worker 负责限定近期改动范围、遵循仓库规范并证明行为等价。
- **单 Cycle TDD** — `/smart:one-by-one` 验证一个最小 Red，再指导用户完成对应 Green。
- **结对手写** — `/smart:pair-write` 为一个用户手写步骤同轮提供注释骨架和直接展开的完整参考实现，默认只检查书写是否正确以及落盘内容是否与指导一致。
- **Wiki 生成** — `/smart:generate-wiki` 把资料整理为 GitLab、GitHub 或本地 Markdown Wiki，并安全发布。
- **双语 Skills PDF** — `/smart:github-skills-pdf` 固定 GitHub skills 仓库版本并生成经验证的英中 A4 手册。
- **个人周报** — `/smart:my-weekly` 按自然周汇总当前用户的 Git 提交。
- **内置编码规则** — 预置规则文件（如 Pydantic V2 标准）存于 `rules/` 目录，按需软链到项目的 `.claude/rules/` 即可激活。
- **学习模式** — `/smart:learning 1` 开启持久化的“用户写、AI 审”流程；`0` 关闭，无参数查看状态。只修改 `.claude/CLAUDE.local.md` 中的受管区块。

---

## 使用方式

**💬 明确调用** — 每个 skill 只在用户指定名称时启动：
Claude Code 使用 `/smart:*`，Codex 使用 `$smart:*`。

**⌨️ Skill 命令** — 在 Codex 中把 `/smart:` 替换为 `$smart:`：

| 命令 | 作用 |
|---|---|
| `/smart:commit` | 仅提交（智能分组，自动生成 message） |
| `/smart:pr [分支]` | 创建或更新 PR；无参数须确认默认 `main`，有参数直接执行；不自动合并 |
| `/smart:clean-branches [分支]` | 清理完整合并到目标的本地和远端分支；无参数须确认默认 `main`；保留保护分支和 worktree 占用分支 |
| `/smart:close-issue <IID或URL>` | 只读核对单个 GitLab Issue；明确授权关闭后，先发布可审计的开发资产记录，再关闭 Issue |
| `/smart:code-simplifier [路径或diff]` | 使用一个全新上下文 worker 简化近期代码，同时保持可观察行为不变 |
| `/smart:matt-implement-all-tickets` | 显式加载 Matt `/implement` 后，串行实现并关闭当前 `/to-tickets` 输出 |
| `/smart:generate-wiki` | 把资料整理为受保护的 GitLab、GitHub 或本地 Wiki |
| `/smart:github-skills-pdf [--notes 2\|4]` | 从 GitHub skills 仓库生成经验证的英中 A4 手册 |
| `/smart:hud [0\|1\|2\|reset\|normal\|all]` | 安装状态栏（`1`/`normal`=简化版，`2`/`all`=完整版）或恢复备份（`0`/`reset`），user 作用域 |
| `/smart:help [skill\|hook\|agent]` | 显示所有插件组件概览（或按类别筛选） |
| `/smart:learning [0\|1]` | 持久化学习模式：`1` 开启、`0` 关闭、无参数查看状态；用户写代码，AI 逐步审阅 |
| `/smart:local` | 创建被 Git 忽略的个人配置文件，不覆盖已有笔记 |
| `/smart:my-weekly <repo> [-N]` | 按指定自然周汇总当前用户的 Git 提交 |
| `/smart:one-by-one` | 每次执行一个最小 Red-to-Green Cycle |
| `/smart:pair-write` | 引导用户手写一个步骤，再对照骨架和参考实现检查落盘代码 |

---

## Smart Commit

`commit`、`pr`、`clean-branches` 同时在 Codex 元数据中禁用自动调用，必须由用户明确触发。

`/smart:commit` 读取状态、已暂存和未暂存 diff、未追踪文件内容及近期历史；先按 type、再按独立目的分组，同一文件可按改动块拆分；提交前简要列出各组的提交信息和文件。

Claude Code 使用 `haiku` 执行整个 turn。Codex 把完整工作流交给一个低 reasoning 的 `gpt-5.6-luna` worker；Luna 不可用时，用用户配置的默认子 agent 重试一次。主 agent 不自行分组或提交。

每组只暂存明确路径或改动块，提交前核对暂存差异，禁止全量暂存。技能输出提交哈希、提交信息和剩余改动，不运行检查、不改版本、不 push，也不创建 PR。


---

## 内置规则

插件预置了编码规则文件，存放在 `rules/` 目录下。按需将规则文件软链到项目的 `.claude/rules/` 中即可激活：

```bash
ln -s /path/to/plugin/rules/pydantic-v2.md .claude/rules/pydantic-v2.md
```

**可用规则：**

| 规则文件 | 约束内容 |
|---|---|
| `pydantic-v2.md` | Pydantic V2 规范：`ConfigDict`、校验器、判别联合、`TypeAdapter`、`RootModel`、`SecretStr`、`pydantic-settings`、V1→V2 迁移 |
| `python-3.14.md` | Python 3.14 规范：延迟注解、`[T]` 泛型、`@override`、`Self`、`TaskGroup`、`StrEnum`、`datetime.UTC`、子解释器、`match` 守卫 |
| `fastapi.md` | FastAPI 0.115+ 规范：`Annotated` 依赖注入、`lifespan`、`APIRouter` 组织、`BackgroundTasks`、`dependency_overrides`、安全作用域 |
| `sqlalchemy-v2.md` | SQLAlchemy 2.0 规范：`DeclarativeBase`、`Mapped[T]`、命名约定、异步会话、`AsyncAttrs`、`selectinload`、UPSERT、Alembic |

规则默认不激活，按需软链即可。

---

## HUD（状态栏）

一条命令安装功能丰富的状态栏：

```
/smart:hud
```

![hud](./assets/imgs/hud.png)

**显示内容（6 行）：**

| 行 | 内容 |
|----|------|
| 1 | 会话 ID / 会话名、模型@版本、总花费（USD） |
| 2 | 目录、Git 分支（dirty/ahead/behind/stash）、最近 commit 时间、worktree 名称、电池 |
| 3 | 上下文进度条 + tokens + cache、速率限制（5h/7d）含重置倒计时、会话时长、agent 名称 |
| 4 | CPU、内存、磁盘、运行时间、Runtime 版本（Node/Python/Go/Rust/Ruby）、本机 IP |
| 5 | 工具调用统计（Bash/Skill/Agent/Edit 次数，从 transcript 实时解析） |
| 6 | 输出风格、vim 模式（仅启用时显示） |

**命令：**

| 命令 | 操作 |
|------|------|
| `/smart:hud` · `/smart:hud 2` · `/smart:hud all` | 安装完整版状态栏（全部 6 行）到 user 作用域，自动备份 |
| `/smart:hud 1` · `/smart:hud normal` | 安装简化版状态栏（仅 session + ctx） |
| `/smart:hud 0` · `/smart:hud reset` | 从备份恢复之前的状态栏 |

**注意：** 跨平台（macOS + Linux/WSL/Ubuntu）—— 自动检测操作系统，电量、CPU、内存、IP 各取对应命令。需要 `jq`；缺失时 `/smart:hud` 会自动安装（apt/dnf/pacman/apk/brew）。

---

## 会话 Hooks

插件包含在会话边界和工具调用时触发的 hooks：

| Hook | 触发时机 | 功能 |
|------|---------|------|
| `greet.sh` | `SessionStart` | 通过 macOS TTS（`say`）播放欢迎语 |
| `session-logs.py` | `PreToolUse`（所有工具） | 将每次工具调用的完整输入记录到 `.smart/session-logs/<日期>/<session_id>.json` |

内置 hook 配置在 Claude 兼容宿主中通过 `${CLAUDE_PLUGIN_ROOT}` 解析路径。TTS hooks 在后台运行（`nohup &`），不阻塞宿主进程。

---

## 前置要求

- **Claude Code** 或 **Codex**（支持插件）—— 插件内置两套清单，在任一宿主都能原生运行
- `git`
- Matt Pocock Skills 的 `/implement` — `/smart:matt-implement-all-tickets` 必需
- [`gh` CLI](https://cli.github.com/) — `/smart:matt-implement-all-tickets` 使用 GitHub Issues 时需要
- [`glab` CLI](https://gitlab.com/gitlab-org/cli) — `/smart:close-issue` 以及 `/smart:matt-implement-all-tickets` 使用 GitLab Issues 时需要
- Node.js — 供收口脚本使用
- Python 3、`reportlab` 与可嵌入 CJK 字体 — 供 `/smart:github-skills-pdf` 使用
- `jq` — 仅 HUD 状态栏需要（其他功能无需）

---

## 作者

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
