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
