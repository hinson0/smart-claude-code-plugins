#!/bin/bash

# 消耗 stdin，防止 broken pipe
cat > /dev/null

# 守卫：必须有项目目录
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  exit 0
fi

# 读取配置文件
CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/smart.local.md"
AUTO_ACTION="off"

if [ -f "$CONFIG_FILE" ]; then
  # 从 YAML frontmatter 中提取 auto_action 的值
  AUTO_ACTION=$(awk '/^---$/{n++; next} n==1 && /^auto_action:/{gsub(/^auto_action:[[:space:]]*/, ""); gsub(/["'"'"']/, "");
gsub(/[[:space:]]/, ""); print; exit}' "$CONFIG_FILE")
fi

# 关闭或无效 → 静默退出
if [ -z "$AUTO_ACTION" ] || [ "$AUTO_ACTION" = "off" ]; then
  exit 0
fi

# 确定要触发的 skill
if [ "$AUTO_ACTION" = "push" ]; then
  SKILL="smart:push"
else
  SKILL="smart:commit"
fi

# 注入 standing instruction，整个会话生效
echo "{\"systemMessage\": \"[AUTO-ACTION] This project has auto-${AUTO_ACTION} enabled (configured in .claude/smart.local.md). After you finish ANY task that modifies files, you MUST invoke the Skill tool with skill=\\\"${SKILL}\\\" before ending your response. Do not ask for confirmation — just invoke it. If the user explicitly says not to commit/push, respect that for that specific task only.\"}"