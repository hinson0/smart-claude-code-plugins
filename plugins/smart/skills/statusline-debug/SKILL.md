---
name: Statusline Debug
description: >-
  This skill should be used when the user asks to "debug statusline",
  "capture statusline JSON", "log statusline data", "inspect statusline input",
  "dump statusline payload", or wants to know what JSON data Claude Code sends
  to the statusline command. Installs a capture wrapper that saves annotated
  JSONC files to .claude/statusline-logs/YYYY-MM-DD/{session_id}.jsonc with
  inline comments explaining every field.
---

# Statusline Debug

Capture the JSON payload that Claude Code pipes to the statusline command,
annotate every field with an inline `//` comment, and save the result organized
by date and session for inspection.

## How It Works

Claude Code invokes `~/.claude/statusline-command.sh` on every render cycle,
piping a JSON object to stdin. This skill installs a thin wrapper that:

1. Reads the JSON from stdin
2. Converts it to annotated JSONC — each field gets a `// comment` explaining
   its meaning (based on the official statusline docs)
3. Saves to `<project>/.claude/statusline-logs/YYYY-MM-DD/{session_id}.jsonc`
   (overwrites per session — always reflects the latest state)
4. Forwards the JSON to the original statusline script (HUD keeps working)

## Output Structure

```
.claude/statusline-logs/
├── 2026-03-28/
│   ├── 19396686-ba88-49fd-8ef4-307548e254d0.jsonc
│   └── a1b2c3d4-e5f6-7890-abcd-ef1234567890.jsonc
├── 2026-03-29/
│   └── ...
```

Each `.jsonc` file looks like this:

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

## Install Capture

To enable JSONC capture, run these steps in order:

### 1. Back up the current statusline script

```bash
cp ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.pre-capture
```

### 2. Install the capture wrapper

Copy the bundled wrapper script over the active statusline command:

```bash
cp <this-skill>/scripts/statusline-capture-wrapper.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

`<this-skill>` resolves to the directory containing this SKILL.md.

### 3. Inform the user

Tell the user:
- Capture is active. Restart the session (or open a new one) for it to take effect.
- Each statusline render saves to `.claude/statusline-logs/YYYY-MM-DD/{session_id}.jsonc`
  inside whichever project directory is active.
- The HUD continues to display normally via the backed-up original script.

## Remove Capture

To stop logging and restore the original statusline:

```bash
mv ~/.claude/statusline-command.sh.pre-capture ~/.claude/statusline-command.sh
```

Then restart the session.

## Read the Output

After restarting and using Claude Code for a moment, read the annotated JSONC:

```bash
# List captured sessions by date
ls <project>/.claude/statusline-logs/

# Read a specific session's latest snapshot
cat <project>/.claude/statusline-logs/2026-03-28/<session-id>.jsonc
```

Or use the Read tool on the `.jsonc` file.

The file is self-documenting — every field has an inline comment explaining its
meaning. Field reference: https://docs.claude.dev/docs/statusline#available-data

> **Note:** Some fields only appear under certain conditions:
> `vim` (vim mode enabled), `agent` (running with --agent),
> `worktree` (--worktree session), `rate_limits` (when rate limit data is available).
> The JSONC file reflects whatever the current session actually provides.
