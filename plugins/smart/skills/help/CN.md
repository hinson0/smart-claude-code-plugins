---
name: help
description: 展示 Smart 的 skills、hooks 或 agents，可按组件类型筛选。
disable-model-invocation: true
argument-hint: "[skill|hook|agent]（空=显示全部）"
---

读取已安装插件的实际组件，不维护静态目录。

参数接受 `skill`/`skills`、`hook`/`hooks`、`agent`/`agents`；留空显示全部。
使用 `${CLAUDE_PLUGIN_ROOT}`，或从当前 skill 所在位置解析插件根目录。

- Skills：读取 `skills/*/SKILL.md` frontmatter，排除 `help`。显示命令、说明及可选的
  `argument-hint`；Claude Code 使用 `/smart:<name>`，Codex 使用 `$smart:<name>`。
- Hooks：读取 `hooks/hooks.json`，显示事件、脚本，以及脚本开头注释中的一行说明。
- Agents：读取 `agents/*.md` frontmatter，显示名称（缺失则用文件名）、说明首行及模型。

只读取所需元数据，跳过无法读取或格式错误的条目；按对话语言为每个所选类别输出简洁表格。
