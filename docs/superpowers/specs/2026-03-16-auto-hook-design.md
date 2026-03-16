# Auto Hook Design Spec

## Overview

Add a Stop hook to the smart plugin that automatically triggers `commit` or `push` when Claude Code finishes a task. Configurable via `/smart:config` slash command. Default: off.

## Requirements

1. **Stop hook**: When CC finishes a task (Stop event), check config and git status, then block or approve
2. **Configurable action**: `off` (default), `commit`, or `push`
3. **Interactive config**: `/smart:config` slash command to switch modes
4. **Reuse existing skills**: Invoke `smart:commit` or `smart:push` — full pipeline including check and multi-feature splitting
5. **Silent execution**: No user confirmation before auto action
6. **No infinite loop**: Use git status to determine whether to block — clean working tree means approve

## Architecture

### New Files

```
plugins/smart/
├── hooks/
│   ├── hooks.json                 # Stop hook configuration
│   └── auto-commit.sh            # Core script: read config + check git status
├── skills/
│   └── config/                    # /smart:config interactive configuration
│       ├── SKILL.md
│       ├── SKILL_CN.md
│       ├── SKILL_TW.md
│       ├── SKILL_JA.md
│       └── SKILL_KO.md
```

### Modified Files

- `plugins/smart/.claude-plugin/plugin.json` — no structural changes needed (hooks auto-discovered from hooks/ directory)

### Configuration Storage

File: `.claude/smart.local.md` (in user's project root, gitignored)

```yaml
---
auto_action: commit
---
```

Values: `off` (default), `commit`, `push`

## Stop Hook Flow

```
CC finishes task → Stop event fires
                    ↓
            auto-commit.sh executes
                    ↓
        Read .claude/smart.local.md
                    ↓
            auto_action value?
           /        |        \
         off      commit     push
          ↓         ↓          ↓
       approve    check git  check git
       (pass)     status     status
                  ↓    ↓     ↓    ↓
               dirty  clean  dirty  clean
                  ↓     ↓      ↓     ↓
               block  approve  block  approve
         + systemMessage        + systemMessage
      "invoke /smart:commit"  "invoke /smart:push"
```

### Loop Prevention

The hook uses git status as the decision criterion, not a flag file:
- `git diff --quiet` — tracked file modifications
- `git diff --cached --quiet` — staged changes
- `git ls-files --others --exclude-standard` — untracked new files

After the skill commits/pushes, the working tree is clean → next Stop event approves.

## hooks.json

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/auto-commit.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

## auto-commit.sh

```bash
#!/bin/bash

# Drain stdin to prevent broken pipe
cat > /dev/null

# Fallback: any error → approve (never block unexpectedly)
approve() { echo '{"decision": "approve"}'; exit 0; }
trap approve ERR

# 1. Guard: CLAUDE_PROJECT_DIR must be set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  approve
fi

# 2. Guard: git must be available
if ! command -v git &> /dev/null; then
  approve
fi

# 3. Read config
CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/smart.local.md"
AUTO_ACTION="off"

if [ -f "$CONFIG_FILE" ]; then
  AUTO_ACTION=$(awk '/^---$/{n++; next} n==1 && /^auto_action:/{gsub(/^auto_action:[[:space:]]*/, ""); gsub(/["'"'"']/, ""); gsub(/[[:space:]]/, ""); print; exit}' "$CONFIG_FILE")
fi

# 4. Config off or invalid → approve
if [ -z "$AUTO_ACTION" ] || [ "$AUTO_ACTION" = "off" ]; then
  approve
fi

# 5. Check for uncommitted changes
if git -C "$CLAUDE_PROJECT_DIR" diff --quiet 2>/dev/null && \
   git -C "$CLAUDE_PROJECT_DIR" diff --cached --quiet 2>/dev/null && \
   [ -z "$(git -C "$CLAUDE_PROJECT_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
  approve
fi

# 6. Dirty tree → block and instruct Claude
if [ "$AUTO_ACTION" = "push" ]; then
  SKILL="/smart:push"
else
  SKILL="/smart:commit"
fi

cat <<EOF
{"decision": "block", "reason": "auto-action triggered", "systemMessage": "Auto ${AUTO_ACTION} is enabled. Uncommitted changes detected. Invoke ${SKILL} now without asking for confirmation."}
EOF
exit 0
```

## /smart:config Skill

### Interaction Flow

```
User: /smart:config
CC: "Current auto-action: off. Choose:
     1. commit — auto commit when task completes
     2. push   — auto commit + push when task completes
     3. off    — disable auto action"
User: 1
CC: Writes .claude/smart.local.md, confirms "Auto commit enabled"
```

### Skill Responsibilities

1. Read current config from `.claude/smart.local.md` (file not found = `off`)
2. Present options with current selection highlighted
3. Write/update `.claude/smart.local.md` with new value
4. Remind user: hook changes require restarting Claude Code session to take effect
5. Confirm the change to user

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No `.claude/smart.local.md` | Treat as `off`, approve Stop |
| File exists but no `auto_action` | Treat as `off`, approve Stop |
| Invalid `auto_action` value | Treat as `off`, approve Stop |
| Working tree clean | Approve Stop (no action needed) |
| Not a git repo | Approve Stop (skip gracefully) |
| `git` not in PATH | Approve Stop (skip gracefully) |
| `CLAUDE_PROJECT_DIR` not set | Approve Stop (skip gracefully) |
| Skill execution fails | User sees error from skill, next Stop will retry since changes still exist |
| Claude ignores systemMessage | Best-effort mechanism — no direct skill invocation API from hooks. In practice, reliably followed |
| Multiple Stop hooks active (e.g. hookify) | Hooks run in parallel; if any returns block, Stop is blocked |

## Version Impact

- Plugin version: 1.4.0 → 1.5.0 (new feature)
