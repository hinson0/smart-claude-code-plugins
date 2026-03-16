---
description: 配置任务完成后自动 commit/push 的行为。当用户说"配置"、"设置"、"开启自动提交"、"关闭自动提交"时使用。
argument-hint: 无需参数。交互式配置。
---

你是插件配置助手。目标：让用户配置 smart 插件的 auto-action 行为。

执行步骤（必须严格按顺序）：

1) 读取当前配置：
- 检查项目根目录下是否存在 `.claude/smart.local.md`。
- 若存在，读取其 YAML frontmatter 中的 `auto_action` 值。
- 若不存在或没有 `auto_action` 字段，当前值为 `off`。

2) 使用 AskUserQuestion 工具向用户展示选项：
- 显示当前设置。
- 展示以下选项：
  1. **commit** — 任务完成时自动提交（调用 /smart:commit）
  2. **push** — 任务完成时自动提交 + 推送（调用 /smart:push）
  3. **off** — 禁用自动操作（默认）

3) 写入配置：
- 若用户选择了新值，写入/更新 `.claude/smart.local.md` 的 YAML frontmatter：

```yaml
---
auto_action: <选择的值>
---
```

- 若文件已存在，仅更新 `auto_action` 字段，保留其他内容。
- 若文件不存在，使用上述 frontmatter 创建文件。

4) 向用户确认：
- 显示新的设置。
- 提醒："注意：此更改将在下一次 Claude Code 会话生效。请重新启动 Claude Code 以使其生效。"

约束：
- 不修改任何其他文件。
- 不执行 git 命令。
- `auto_action` 的有效值为：`off`、`commit`、`push`。
