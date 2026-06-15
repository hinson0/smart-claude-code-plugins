---
name: local
description: Personal local config for Claude Code sessions. Trigger on /smart:local, or when the user says "create CLAUDE.local.md", "setup local memory", "local preferences", "git-ignore my local claude file", or wants a per-project personal memory file that is never committed. Bootstraps a git-ignored `.claude/CLAUDE.local.md` in the current project, seeded with the personal preferences below, and ensures it is git-ignored. The personal preferences also apply on their own: always reply in Simplified Chinese, store Plan Mode files under `.claude/plans/`.
argument-hint: "（无参数 —— 创建一个被 git 忽略的 .claude/CLAUDE.local.md）"
---

## 个人偏好（始终生效）

全程使用**简体中文**回复，包括：

- 日常沟通、技术讨论、注释解释均使用**中文**，包括你的内部 thinking/reasoning 过程
- 生成 spec / plan 默认使用中文
- 必要的英文技术词可以保留。

Claude Code Plan Mode 的计划文件保存在**当前项目目录内**：
`.claude/plans/YYYY_MM_DD_HH_mm-<name>.md`

## 动作：创建一个被 git 忽略的 `.claude/CLAUDE.local.md`

当本技能被显式触发（`/smart:local`）时，为当前项目建立一个不进版本控制的个人记忆文件。它的用途是存放机器/个人专属的笔记（上面的偏好、本地路径、临时上下文等），这些内容绝不应进入共享提交。

1. **解析项目根目录。** 用 `git rev-parse --show-toplevel`；若不在 git 仓库中，退回当前工作目录。
2. **确保目录存在。** `mkdir -p <root>/.claude`。
3. **文件缺失则创建。** 若 `<root>/.claude/CLAUDE.local.md` 不存在，按下方模板写入；若已存在，则保持原样、绝不覆盖用户自己的笔记——仅报告它已存在。
4. **确保被 git 忽略**（仅在 git 仓库内有意义）。用 `git check-ignore -q .claude/CLAUDE.local.md` 检查。若该命令失败（文件尚未被忽略），把 `.claude/CLAUDE.local.md` 这一行追加到 `<root>/.gitignore`（不存在则创建）。此操作幂等——绝不添加重复行，也绝不改写 `.gitignore` 的其他内容；用 Edit/Write 工具仅追加单行。
5. **报告**文件的绝对路径（新建还是已存在）以及忽略规则是新增还是已生效。提醒用户 `.claude/CLAUDE.local.md` 是个人文件、不会被提交。

### 全新 `.claude/CLAUDE.local.md` 的模板

```markdown
# CLAUDE.local.md — personal, git-ignored

Per-project notes for this machine/person. Not committed.

## Language
- Reply in Simplified Chinese; keep necessary English technical terms.
- Plan Mode files: `.claude/plans/YYYY_MM_DD_HH_mm-<name>.md`

## Local context
<!-- local paths, credentials location, scratch notes, etc. -->
```

## 约束

- 严格遵循用户要求的路径：`.claude/CLAUDE.local.md`（在 `.claude/` 下，而非项目根）。
- 绝不覆盖已存在的 `.claude/CLAUDE.local.md`；用户内容为准。
- `.gitignore` 一律用 Edit/Write 工具；仅追加单行，绝不整体覆盖。
- 输出语言与用户对话语言一致。
