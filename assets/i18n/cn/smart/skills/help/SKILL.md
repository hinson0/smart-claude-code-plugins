---
description: 当用户说"help"、"帮助"、"有什么功能"、"列出技能"、"列出hook"、"列出agent"、"怎么用"，或想了解 smart 插件的功能概览时使用此技能。
argument-hint: "[skill|hook|agent]（空=显示全部）"
model: haiku
---

通过动态扫描插件目录，展示 smart 插件各组件的格式化概览。

## 确定类别

| 参数               | 类别    |
| ------------------ | ------- |
| _（空）_           | `all`   |
| `skill` / `skills` | `skill` |
| `hook` / `hooks`   | `hook`  |
| `agent` / `agents` | `agent` |

## 扫描指令

### 技能（`skill` 或 `all`）

1. 列出 `${CLAUDE_PLUGIN_ROOT}/skills/` 下的所有子目录。
2. 对每个包含 `SKILL.md` 的子目录，读取 YAML frontmatter 提取：
   - **name**: 目录名（作为 `/smart:<name>` 使用）
   - **description**: frontmatter 中的 `description` 字段
   - **argument-hint**: frontmatter 中的 `argument-hint` 字段（如有）
3. 以表格形式展示：

```
## 技能

| 命令 | 说明 | 参数 |
|------|------|------|
| /smart:check | 自动检测 CI 并执行检查 | （无） |
| /smart:commit | 语义分组提交 | （无） |
| ...  | ...  | ...  |
```

列表中跳过 `help` 技能本身。

### Hooks（`hook` 或 `all`）

1. 读取 `${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json`。
2. 对每种事件类型（SessionStart、PreToolUse、SessionEnd 等），列出已配置的 hook。
3. 对每个 hook 脚本，读取 shebang 之后的首段注释行（`#` 开头）提取一行描述。
4. 以表格形式展示：

```
## Hooks

| 事件 | 脚本 | 说明 |
|------|------|------|
| SessionStart | greet.sh | 会话开始时问候 |
| PreToolUse | session-logs.py | 记录工具调用输入 |
| SessionEnd | goodbye.sh | 会话结束时告别 |
```

### Agents（`agent` 或 `all`）

1. 列出 `${CLAUDE_PLUGIN_ROOT}/agents/` 下的所有 `.md` 文件。
2. 对每个文件，读取 YAML frontmatter 提取：
   - **name**: frontmatter 中的 `name` 字段（或文件名去掉扩展名）
   - **description**: frontmatter 中的 `description` 字段（仅第一行）
   - **model**: frontmatter 中的 `model` 字段
3. 以表格形式展示：

```
## Agents

| 名称 | 说明 | 模型 |
|------|------|------|
| <名称> | <说明> | <模型> |
```

## 输出格式

`all` 类别时，合并三个 section 并加标题：

```
# Smart 插件组件

<技能表格>

<hooks 表格>

<agents 表格>
```

指定具体类别时，仅显示该 section 并附一行简要说明。

## 约束

- 不要将完整文件内容读入上下文 — 仅读取 frontmatter 和开头注释。
- 信息展示应简洁。仅使用一行描述，不展示完整 skill body。
- 若文件不可读或 frontmatter 格式异常，跳过该条目继续扫描。
- 输出语言与用户对话语言一致。
