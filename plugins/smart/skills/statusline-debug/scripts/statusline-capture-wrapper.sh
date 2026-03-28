#!/usr/bin/env bash
# Statusline JSONC Capture Wrapper
#
# Intercepts the raw JSON payload that Claude Code pipes to the statusline
# command, converts it to annotated JSONC with inline comments explaining
# each field, saves to <project>/.claude/statusline-logs/YYYY-MM-DD/<session_id>.jsonc,
# then forwards the payload to the original statusline script so the HUD keeps working.

set -euo pipefail

INPUT=$(cat)

# Extract project directory and session_id from the JSON payload
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // .workspace.current_dir // empty' 2>/dev/null || true)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)

# Convert JSON to annotated JSONC and save by date/session
if [[ -n "$PROJECT_DIR" && -d "$PROJECT_DIR/.claude" && -n "$SESSION_ID" ]]; then
    TODAY=$(date +%Y-%m-%d)
    LOG_DIR="$PROJECT_DIR/.claude/statusline-logs/$TODAY"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/${SESSION_ID}.jsonc"
    echo "$INPUT" | python3 -c '
import json, sys, re
from datetime import datetime, timezone

data = json.load(sys.stdin)
lines = json.dumps(data, indent=2, ensure_ascii=False).split("\n")

# (parent_key, field_key) -> inline comment
C = {
    # ── top-level ──
    ("", "session_id"): "唯一会话标识符",
    ("", "transcript_path"): "对话记录文件路径",
    ("", "cwd"): "当前工作目录（与 workspace.current_dir 相同）",
    ("", "model"): "模型信息",
    ("", "workspace"): "工作区信息",
    ("", "version"): "Claude Code 版本号",
    ("", "output_style"): "输出样式配置",
    ("", "cost"): "会话成本与统计",
    ("", "context_window"): "上下文窗口状态",
    ("", "exceeds_200k_tokens"): "最近 API 响应总 token 是否超过 200K（固定阈值，与实际窗口大小无关）",
    ("", "rate_limits"): "速率限制信息",
    ("", "vim"): "Vim 模式信息（仅在启用 vim 模式时出现）",
    ("", "agent"): "代理信息（仅在使用 --agent 运行时出现）",
    ("", "worktree"): "Worktree 信息（仅在 --worktree 会话中出现）",
    # ── model ──
    ("model", "id"): "当前模型标识符",
    ("model", "display_name"): "模型显示名称",
    # ── workspace ──
    ("workspace", "current_dir"): "当前工作目录",
    ("workspace", "project_dir"): "启动 Claude Code 时的目录（会话期间 cwd 可能改变，此值不变）",
    ("workspace", "added_dirs"): "额外添加的目录列表",
    # ── cost ──
    ("cost", "total_cost_usd"): "总会话成本（美元）",
    ("cost", "total_duration_ms"): "自会话开始的总挂钟时间（毫秒）",
    ("cost", "total_api_duration_ms"): "等待 API 响应的总时间（毫秒）",
    ("cost", "total_lines_added"): "累计新增代码行数",
    ("cost", "total_lines_removed"): "累计删除代码行数",
    # ── context_window ──
    ("context_window", "total_input_tokens"): "整个会话的累积输入 token 总数",
    ("context_window", "total_output_tokens"): "整个会话的累积输出 token 总数",
    ("context_window", "context_window_size"): "最大上下文窗口大小（token），默认 200K，扩展模型为 1M",
    ("context_window", "used_percentage"): "已使用上下文窗口百分比（仅计输入 token）",
    ("context_window", "remaining_percentage"): "剩余上下文窗口百分比",
    ("context_window", "current_usage"): "最近一次 API 调用的 token 明细（首次调用前为 null）",
    # ── current_usage ──
    ("current_usage", "input_tokens"): "当前上下文中的输入 token",
    ("current_usage", "output_tokens"): "本次生成的输出 token",
    ("current_usage", "cache_creation_input_tokens"): "写入缓存的 token 数",
    ("current_usage", "cache_read_input_tokens"): "从缓存读取的 token 数",
    # ── output_style ──
    ("output_style", "name"): "当前输出样式名称",
    # ── rate_limits ──
    ("rate_limits", "five_hour"): "5 小时滚动窗口限制",
    ("rate_limits", "seven_day"): "7 天滚动窗口限制",
    ("five_hour", "used_percentage"): "5 小时速率限制使用百分比",
    ("five_hour", "resets_at"): "5 小时限制重置的 Unix 时间戳",
    ("seven_day", "used_percentage"): "7 天速率限制使用百分比",
    ("seven_day", "resets_at"): "7 天限制重置的 Unix 时间戳",
    # ── vim ──
    ("vim", "mode"): "当前 Vim 模式（NORMAL 或 INSERT）",
    # ── agent ──
    ("agent", "name"): "当前代理名称",
    # ── worktree ──
    ("worktree", "name"): "活跃 worktree 名称",
    ("worktree", "path"): "worktree 目录的绝对路径",
    ("worktree", "branch"): "worktree 的 Git 分支名称",
    ("worktree", "original_cwd"): "进入 worktree 前的工作目录",
    ("worktree", "original_branch"): "进入 worktree 前的 Git 分支",
}

ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
print(f"// Claude Code Statusline JSON — captured {ts}")
print(f"// Ref: https://docs.claude.dev/docs/statusline#available-data")

stack = []
for line in lines:
    stripped = line.lstrip()
    m = re.match(r"\"([^\"]+)\"\s*:", stripped)
    if m:
        key = m.group(1)
        parent = stack[-1] if stack else ""
        comment = C.get((parent, key))
        if stripped.rstrip(",").endswith(("{", "[")):
            stack.append(key)
        print(f"{line} // {comment}" if comment else line)
    else:
        if stripped.rstrip(",") in ("}", "]"):
            if stack:
                stack.pop()
        print(line)
' > "$LOG_FILE" 2>/dev/null || true
fi

# Forward to the original (backed-up) statusline command
if [[ -f ~/.claude/statusline-command.sh.pre-capture ]]; then
    echo "$INPUT" | bash ~/.claude/statusline-command.sh.pre-capture
fi
