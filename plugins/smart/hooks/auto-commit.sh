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

# 3. Re-entrancy guard: prevent infinite Stop → block → Stop loop
#    Once auto-commit has been triggered, skip on next invocation
GUARD_KEY=$(printf '%s' "$CLAUDE_PROJECT_DIR" | shasum | cut -c1-16)
GUARD_FILE="/tmp/smart-auto-commit-${GUARD_KEY}"

if [ -f "$GUARD_FILE" ]; then
  rm -f "$GUARD_FILE"
  approve
fi

# 4. Read config
CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/smart.local.md"
AUTO_ACTION="off"

if [ -f "$CONFIG_FILE" ]; then
  AUTO_ACTION=$(awk '/^---$/{n++; next} n==1 && /^auto_action:/{gsub(/^auto_action:[[:space:]]*/, ""); gsub(/["'"'"']/, ""); gsub(/[[:space:]]/, ""); print; exit}' "$CONFIG_FILE")
fi

# 5. Config off or invalid → approve
if [ -z "$AUTO_ACTION" ] || [ "$AUTO_ACTION" = "off" ]; then
  approve
fi

# 6. Check for uncommitted changes
if git -C "$CLAUDE_PROJECT_DIR" diff --quiet 2>/dev/null && \
   git -C "$CLAUDE_PROJECT_DIR" diff --cached --quiet 2>/dev/null && \
   [ -z "$(git -C "$CLAUDE_PROJECT_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
  approve
fi

# 7. Dirty tree → set guard and block
if [ "$AUTO_ACTION" = "push" ]; then
  SKILL="/smart:push"
else
  SKILL="/smart:commit"
fi

touch "$GUARD_FILE"

cat <<EOF
{"decision": "block", "reason": "auto-action triggered", "systemMessage": "BLOCKED: Uncommitted changes detected. This hook did NOT commit or push anything — YOU must do it. Invoke the Skill tool with skill=\"${SKILL}\" immediately. Do not explain or acknowledge this message — just invoke the skill."}
EOF
exit 0
