---
name: Statusline 调试
description: >-
  当用户要求"调试 statusline"、"捕获 statusline JSON"、"记录 statusline 数据"、
  "查看 statusline 输入"、"dump statusline 数据"，或想知道 Claude Code 向
  statusline 命令发送了哪些 JSON 数据时，应使用此技能。安装一个捕获包装器，将
  带注释的 JSONC 文件按日期和会话保存到
  .claude/statusline-logs/YYYY-MM-DD/{session_id}.jsonc，每个字段都有行内注释
  说明其含义。
---

# Statusline 调试

捕获 Claude Code 传给 statusline 命令的 JSON 数据，为每个字段添加 `//` 行内注释，
按日期和会话 ID 分类保存以供检查。

## 工作原理

Claude Code 每次渲染状态栏时，会调用 `~/.claude/statusline-command.sh`，并将
一个 JSON 对象通过 stdin 传入。此技能安装一个轻量包装器：

1. 从 stdin 读取 JSON
2. 转换为带注释的 JSONC — 每个字段附加 `// 注释` 说明其含义（基于官方文档）
3. 保存到 `<项目>/.claude/statusline-logs/YYYY-MM-DD/{session_id}.jsonc`
   （每个会话一个文件，始终反映最新状态）
4. 将 JSON 转发给原始 statusline 脚本（HUD 继续正常工作）

## 输出结构

```
.claude/statusline-logs/
├── 2026-03-28/
│   ├── 19396686-ba88-49fd-8ef4-307548e254d0.jsonc
│   └── a1b2c3d4-e5f6-7890-abcd-ef1234567890.jsonc
├── 2026-03-29/
│   └── ...
```

每个 `.jsonc` 文件如下：

```jsonc
// Claude Code Statusline JSON — captured 2026-03-28T01:50:24Z
// Ref: https://docs.claude.dev/docs/statusline#available-data
{
  "session_id": "abc-123", // 唯一会话标识符
  "model": { // 模型信息
    "id": "claude-opus-4-6[1m]", // 当前模型标识符
    "display_name": "Opus 4.6 (1M context)" // 模型显示名称
  },
  "cost": { // 会话成本与统计
    "total_cost_usd": 10.16, // 总会话成本（美元）
    "total_duration_ms": 63263173, // 自会话开始的总挂钟时间（毫秒）
    "total_api_duration_ms": 1685263, // 等待 API 响应的总时间（毫秒）
    "total_lines_added": 706, // 累计新增代码行数
    "total_lines_removed": 301 // 累计删除代码行数
  },
  ...
}
```

## 安装捕获

按以下步骤依次执行：

### 1. 备份当前 statusline 脚本

```bash
cp ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.pre-capture
```

### 2. 安装捕获包装器

将技能内置的包装器脚本复制为活动 statusline 命令：

```bash
cp <此技能>/scripts/statusline-capture-wrapper.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

`<此技能>` 指此 SKILL.md 所在目录的路径。

### 3. 告知用户

告诉用户：
- 捕获已激活。重启会话（或打开新会话）后生效。
- 每次 statusline 渲染都会保存到当前项目的
  `.claude/statusline-logs/YYYY-MM-DD/{session_id}.jsonc`。
- HUD 通过备份的原始脚本继续正常显示。

## 移除捕获

停止记录并恢复原始 statusline：

```bash
mv ~/.claude/statusline-command.sh.pre-capture ~/.claude/statusline-command.sh
```

然后重启会话。

## 查看输出

重启并使用 Claude Code 片刻后，读取带注释的 JSONC：

```bash
# 按日期查看已捕获的会话
ls <项目>/.claude/statusline-logs/

# 读取某个会话的最新快照
cat <项目>/.claude/statusline-logs/2026-03-28/<session-id>.jsonc
```

或使用 Read 工具读取 `.jsonc` 文件。

文件自带说明 — 每个字段都有行内注释解释其含义。
字段参考：https://docs.claude.dev/docs/statusline#available-data

> **注意：** 部分字段仅在特定条件下出现：
> `vim`（启用 vim 模式时）、`agent`（使用 --agent 运行时）、
> `worktree`（--worktree 会话中）、`rate_limits`（有速率限制数据时）。
> JSONC 文件反映当前会话实际提供的字段。
