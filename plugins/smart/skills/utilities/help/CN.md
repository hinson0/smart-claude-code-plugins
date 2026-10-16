---
name: help
description: 列出 Smart 的每个 skill，简要说明其能力和用途。
disable-model-invocation: true
---

显示已安装 Smart 的全部 skill 简表，包含 `help` 自身。
始终显示完整简表；接受并忽略旧参数。

使用 `${CLAUDE_PLUGIN_ROOT}`，或从当前 skill 目录向上三级解析插件根目录。
读取 `skills/*/SKILL.md` 和 `skills/*/*/SKILL.md` 的 frontmatter。
以各 skill 的 `name` 和 `description` 为事实来源。
不维护静态目录，不调用列出的 skill。

使用用户的语言输出一张表：分类 | 调用名 | 能力与用途。
Claude Code 使用 `/smart:<name>`，Codex 使用 `$smart:<name>`。
按 `git`、`coding`、`docs`、`utilities` 分组；`help` 归入 `utilities`。
组内按名称排序，分类名称翻译为用户语言。
每个 skill 用一句短句说明做什么、用于什么。
省略参数、实现细节、hooks 和 agents。

只读取所需元数据。遇到不可读或格式错误的条目时跳过。
在表后用一条简短说明列出遗漏条目，不声称列表完整。
