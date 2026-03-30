---
description: 当用户说"capture context"、"save context"、"context snapshot"、"token-log"、"token log"、"context"、"context usage"、"statusline"、"statusline usage"、"dump statusline"、"save session info"、"export session"，或想要将当前 Claude Code 会话的 statusline 数据导出为带注释的 JSONC 快照到 .claude/token-logs/ 时，应使用此技能。通过 /smart:token-log 显式调用。
argument-hint: 无需参数。捕获当前 statusline 数据快照。
---

# 上下文捕获

捕获当前 Claude Code 会话的 statusline 数据，保存为带描述性注释的 JSONC 文件。

## 前提条件

statusline 脚本必须已配置并正在运行。脚本每次更新时会将原始 JSON 保存到 `~/.claude/.statusline-latest.json`。若该文件不存在，告知用户 statusline 未配置或尚未运行。

## 步骤

### 1) 读取 statusline 数据

读取 `~/.claude/.statusline-latest.json`。若文件缺失、为空或包含非法 JSON（如写入被中断），清晰报告错误并停止。

### 2) 确定输出语言

根据当前对话语言决定 JSONC 注释语言：
- 用户使用中文交流 → 中文注释
- 用户使用英文交流 → 英文注释
- 其他情况，跟随用户语言

查阅 `references/field-descriptions.md` 获取各语言的注释文本。

### 3) 格式化为带注释的 JSONC

按以下结构构建 JSONC 文件：

```
// Claude Code Statusline JSON — captured {ISO_8601_TIMESTAMP}
// Ref: https://docs.claude.dev/docs/statusline#available-data
{
  "field": value, // 用户语言的字段描述
  ...
}
```

规则：
- 添加捕获时间戳头部（当前 UTC 时间，ISO 8601 格式）
- 根据 `references/field-descriptions.md` 中的描述，在每个字段后添加注释
- 对嵌套对象，在左花括号行添加注释描述该组
- 保留源数据中的精确 JSON 值——不修改、不四舍五入、不省略任何字段
- 包含源 JSON 中存在的所有字段，包括条件字段（vim、agent、worktree）
- 省略源数据中不存在或为 null 的字段

### 4) 写入文件

1. 从 JSON 数据中提取 `session_id`
2. 确定项目根目录（使用当前工作目录）
3. 按需创建输出目录：`{项目根}/.claude/token-logs/`
4. 写入：`{项目根}/.claude/token-logs/{session_id}.jsonc`
5. 若文件已存在则覆盖（同一会话，以最新快照为准）
6. 若 `.claude/token-logs/` 尚未在项目的 `.gitignore` 中，提醒用户添加——这些是个人会话快照，不属于共享项目数据

### 5) 报告

显示简要确认信息：
- 输出文件路径
- 会话 ID
- 捕获时间戳

## 附加资源

### 参考文件

- **`references/field-descriptions.md`** — 双语（EN/CN）statusline JSON 字段描述。格式化 JSONC 注释时读取此文件。
