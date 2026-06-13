#!/bin/bash
# Claude Code statusLine 命令 — 超级增强版（跨平台：macOS + Linux/WSL/Ubuntu）
#
# 布局：
#   行 1：@ 会话标识  |  模型@版本  |  $费用
#   行 2：~/目录  |  ⎇ 分支[dirty][↑↓ ahead/behind][≡stash]  |  commit时间  |  wt:worktree  |  电池
#   行 3：ctx进度条+tokens+cache  |  rate-limits(含重置倒计时)  |  会话时长  |  agent
#   行 4：CPU(load)  Mem  Disk  uptime  |  Runtime(Node/Py/Go/Rust/Ruby)  |  本机IP
#   行 5：工具调用统计
#   行 6：输出风格  |  vim模式（可选）

# 确保常见的可执行目录都在 PATH 中。
# jq 在不同平台/安装方式下位置各异：
#   ~/.local/bin（pip/手动）· /opt/homebrew/bin（macOS arm brew）· /usr/local/bin（macOS intel brew）
#   /usr/bin（apt/dnf/pacman）· /snap/bin（snap）。Claude Code 的 statusLine 子进程 PATH 往往很精简。
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/snap/bin:$PATH"

# 硬依赖：jq。下面每个字段都靠 jq 解析 JSON；缺了它整个 statusline 就只剩寥寥几个 /proc 字段。
# 此时用一行可操作的提示直接退出，而不是刷一堆报错。
if ! command -v jq >/dev/null 2>&1; then
  printf '\033[38;5;166m⚠ statusline: jq not found\033[0m \033[2m— install it: Linux "sudo apt install jq" (or dnf/pacman/apk) · macOS "brew install jq"\033[0m\n'
  exit 0
fi

input=$(cat)

# 保存原始 JSON 供上下文捕获（被 smart:token-log 技能使用）
echo "$input" > "$HOME/.claude/.statusline-latest.json" 2>/dev/null

# ══════════════════════════════════════════════════════════
# 0. 操作系统检测
# ══════════════════════════════════════════════════════════
OS=$(uname -s)
IS_MACOS=false
IS_LINUX=false
case "$OS" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
esac

# ══════════════════════════════════════════════════════════
# 1. 从 JSON 提取 Claude 数据
# ══════════════════════════════════════════════════════════
model=$(echo "$input"          | jq -r '.model.display_name // ""')
cwd=$(echo "$input"            | jq -r '.workspace.current_dir // .cwd // ""')
used=$(echo "$input"           | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input"      | jq -r '.context_window.remaining_percentage // empty')
ctx_size=$(echo "$input"       | jq -r '.context_window.context_window_size // empty')
in_tok=$(echo "$input"         | jq -r '.context_window.current_usage.input_tokens // empty')
out_tok=$(echo "$input"        | jq -r '.context_window.current_usage.output_tokens // empty')
cache_read=$(echo "$input"     | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
session_id=$(echo "$input"     | jq -r '.session_id // ""')
session_name=$(echo "$input"   | jq -r '.session_name // ""')
style=$(echo "$input"          | jq -r '.output_style.name // ""')
vim_mode=$(echo "$input"       | jq -r '.vim.mode // ""')
five_pct=$(echo "$input"       | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"       | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "$input"     | jq -r '.rate_limits.five_hour.resets_at // empty')
version=$(echo "$input"        | jq -r '.version // ""')
transcript_path=$(echo "$input"| jq -r '.transcript_path // ""')
agent_name=$(echo "$input"     | jq -r '.agent.name // ""')
worktree_name=$(echo "$input"  | jq -r '.worktree.name // ""')
worktree_branch=$(echo "$input"| jq -r '.worktree.branch // ""')
total_cost=$(echo "$input"     | jq -r '.cost.total_cost_usd // empty')

# 模型短名："Claude Sonnet 4.6" → "Sonnet 4.6"
model_short=$(echo "$model" | sed 's/^Claude //')

# 目录：若处于 worktree 中，显示原始仓库根目录而非 worktree 路径
if [ -n "$worktree_name" ]; then
  display_cwd=$(echo "$cwd" | sed 's|/\.claude/worktrees/[^/]*$||')
else
  display_cwd="$cwd"
fi
short_cwd=$(echo "$display_cwd" | sed "s|^$HOME|~|")
short_cwd_len=$(echo -n "$short_cwd" | wc -c | tr -d ' ')
if [ "$short_cwd_len" -gt 40 ] 2>/dev/null; then
  short_cwd="…/$(echo "$short_cwd" | awk -F/ '{print $(NF-1)"/"$NF}')"
fi

# ══════════════════════════════════════════════════════════
# 2. Git 信息（跳过可选锁以避免阻塞）
# ══════════════════════════════════════════════════════════
branch=""
dirty=""
ahead_behind=""
stash_count=""
last_commit_rel=""

if [ -n "$cwd" ] && GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
           || echo "?")

  # dirty 检查（未暂存或已暂存的改动）
  if ! GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --quiet 2>/dev/null \
    || ! GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    dirty="*"
  fi

  # 未跟踪文件
  if [ -n "$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
    dirty="${dirty}?"
  fi

  # 相对远端 ahead / behind
  upstream=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
  if [ -n "$upstream" ]; then
    ahead=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "0")
    behind=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")
    ab=""
    [ "$ahead"  -gt 0 ] && ab="${ab}↑${ahead}"
    [ "$behind" -gt 0 ] && ab="${ab}↓${behind}"
    [ -n "$ab" ] && ahead_behind="$ab"
  fi

  # stash 数量
  sc=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  [ "$sc" -gt 0 ] 2>/dev/null && stash_count="≡${sc}"

  # 最近一次 commit 的相对时间（紧凑格式）
  last_commit_rel=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" log -1 --format="%cr" 2>/dev/null \
    | sed 's/ ago//' \
    | sed 's/ seconds\?/s/' \
    | sed 's/ minutes\?/m/' \
    | sed 's/ hours\?/h/' \
    | sed 's/ days\?/d/' \
    | sed 's/ weeks\?/w/' \
    | sed 's/ months\?/mo/' \
    | sed 's/ years\?/yr/')
fi

# ══════════════════════════════════════════════════════════
# 3. 系统信息（跨平台：macOS + Linux）
# ══════════════════════════════════════════════════════════

# -- CPU 核心数
if $IS_MACOS; then
  cpu_cores=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)
elif $IS_LINUX; then
  cpu_cores=$(nproc 2>/dev/null || echo 1)
else
  cpu_cores=1
fi

# -- CPU 负载（1 分钟平均）
if $IS_MACOS; then
  load1=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
elif $IS_LINUX; then
  load1=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "")
else
  load1=""
fi
cpu_pct=$(awk -v l="$load1" -v c="$cpu_cores" \
  'BEGIN { if(l==""||c==0) print "?"; else { v=l/c*100; if(v>100) v=100; printf "%.0f", v } }' 2>/dev/null || echo "?")

# -- 内存
if $IS_MACOS; then
  page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
  mem_total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  mem_total_gb=$(awk -v b="$mem_total_bytes" 'BEGIN { printf "%.0f", b/1073741824 }')
  mem_info=$(vm_stat 2>/dev/null)
  pages_free=$(echo "$mem_info"     | awk '/Pages free/     {gsub(/\./,"",$3); print $3+0}')
  pages_spec=$(echo "$mem_info"     | awk '/Pages speculative/ {gsub(/\./,"",$3); print $3+0}')
  pages_inact=$(echo "$mem_info"    | awk '/Pages inactive/  {gsub(/\./,"",$3); print $3+0}')
  mem_avail_gb=$(awk -v f="$pages_free" -v s="$pages_spec" -v i="$pages_inact" \
    -v ps="$page_size" \
    'BEGIN { printf "%.1f", (f+s+i)*ps/1073741824 }' 2>/dev/null || echo "?")
  mem_used_gb=$(awk -v t="$mem_total_gb" -v a="$mem_avail_gb" \
    'BEGIN { printf "%.1f", t-a }' 2>/dev/null || echo "?")
  mem_pct=$(awk -v t="$mem_total_bytes" -v a="$mem_avail_gb" \
    'BEGIN { if(t>0) printf "%.0f", (1-a*1073741824/t)*100; else print "?" }' 2>/dev/null || echo "?")
elif $IS_LINUX; then
  mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  mem_avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  mem_total_gb=$(awk -v b="$mem_total_kb" 'BEGIN { printf "%.0f", b/1048576 }')
  if [ "$mem_avail_kb" -gt 0 ] 2>/dev/null; then
    mem_used_gb=$(awk -v t="$mem_total_kb" -v a="$mem_avail_kb" 'BEGIN { printf "%.1f", (t-a)/1048576 }')
    mem_pct=$(awk -v t="$mem_total_kb" -v a="$mem_avail_kb" 'BEGIN { if(t>0) printf "%.0f", (1-a/t)*100; else print "?" }')
  else
    # 回退：用 MemFree + Buffers + Cached
    mem_free_kb=$(awk '/MemFree/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    mem_buf_kb=$(awk '/Buffers/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    mem_cache_kb=$(awk '/^Cached/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    mem_avail_kb=$(( mem_free_kb + mem_buf_kb + mem_cache_kb ))
    mem_used_gb=$(awk -v t="$mem_total_kb" -v a="$mem_avail_kb" 'BEGIN { printf "%.1f", (t-a)/1048576 }')
    mem_pct=$(awk -v t="$mem_total_kb" -v a="$mem_avail_kb" 'BEGIN { if(t>0) printf "%.0f", (1-a/t)*100; else print "?" }')
  fi
else
  mem_total_gb="?"; mem_used_gb="?"; mem_pct="?"
fi

# -- 磁盘（cwd 所在卷）
if [ -n "$cwd" ]; then
  disk_info=$(df -h "$cwd" 2>/dev/null | tail -1)
  disk_used=$(echo "$disk_info" | awk '{print $3}')
  disk_total=$(echo "$disk_info" | awk '{print $2}')
  disk_pct=$(echo "$disk_info"  | awk '{gsub(/%/,"",$5); print $5}')
else
  disk_used="?"; disk_total="?"; disk_pct="?"
fi

# -- 运行时长（紧凑格式，macOS 与 Linux 通用）
uptime_str=$(uptime 2>/dev/null | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' \
  | sed 's/^ *//' | sed 's/  */ /g')

# -- 电池
battery_str=""
if $IS_MACOS; then
  batt_raw=$(pmset -g batt 2>/dev/null | grep -E '[0-9]+%')
  if [ -n "$batt_raw" ]; then
    batt_pct=$(echo "$batt_raw" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    batt_status=$(echo "$batt_raw" | grep -oE '(charging|discharging|charged|AC attached)' | head -1)
    if [ -n "$batt_pct" ]; then
      if echo "$batt_status" | grep -qi 'charg'; then
        battery_str="~${batt_pct}%"
      else
        battery_str="${batt_pct}%bat"
      fi
    fi
  fi
elif $IS_LINUX; then
  # 尝试标准 Linux 电池路径（笔记本、笔记本上的 WSL 适用）
  for bat_path in /sys/class/power_supply/BAT0 /sys/class/power_supply/BAT1; do
    if [ -f "$bat_path/capacity" ]; then
      batt_pct=$(cat "$bat_path/capacity" 2>/dev/null)
      batt_status=$(cat "$bat_path/status" 2>/dev/null)
      if [ -n "$batt_pct" ]; then
        if echo "$batt_status" | grep -qi 'charg'; then
          battery_str="~${batt_pct}%"
        elif echo "$batt_status" | grep -qi 'full'; then
          battery_str="~${batt_pct}%"
        else
          battery_str="${batt_pct}%bat"
        fi
      fi
      break
    fi
  done
fi

# -- 本机 IP（首个非回环 IPv4）
local_ip=""
if $IS_MACOS; then
  local_ip=$(ipconfig getifaddr en0 2>/dev/null \
    || ipconfig getifaddr en1 2>/dev/null \
    || echo "")
elif $IS_LINUX; then
  # 优先 hostname -I（最简单），再回退到 ip 命令
  local_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [ -z "$local_ip" ]; then
    local_ip=$(ip -4 addr show 2>/dev/null \
      | grep -oP '(?<=inet\s)\d+(\.\d+){3}' \
      | grep -v '127\.0\.0\.1' \
      | head -1)
  fi
fi

# ══════════════════════════════════════════════════════════
# 4. 会话时长（跨平台：用 stat 取文件时间戳）
# ══════════════════════════════════════════════════════════
session_duration=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  if $IS_MACOS; then
    birth_ts=$(stat -f %B "$transcript_path" 2>/dev/null || echo "")
    if [ -z "$birth_ts" ] || [ "$birth_ts" = "0" ]; then
      birth_ts=$(stat -f %m "$transcript_path" 2>/dev/null || echo "")
    fi
  elif $IS_LINUX; then
    # %W = 创建时间（ext4 上常为 0），%Y = 修改时间
    birth_ts=$(stat -c %W "$transcript_path" 2>/dev/null || echo "")
    if [ -z "$birth_ts" ] || [ "$birth_ts" = "0" ]; then
      birth_ts=$(stat -c %Y "$transcript_path" 2>/dev/null || echo "")
    fi
  fi
  if [ -n "$birth_ts" ] && [ "$birth_ts" != "0" ]; then
    now_ts=$(date +%s)
    elapsed=$(( now_ts - birth_ts ))
    if [ "$elapsed" -lt 0 ]; then elapsed=0; fi
    dur_h=$(( elapsed / 3600 ))
    dur_m=$(( (elapsed % 3600) / 60 ))
    dur_s=$(( elapsed % 60 ))
    if [ "$dur_h" -gt 0 ]; then
      session_duration="$(printf "%dh%02dm" "$dur_h" "$dur_m")"
    elif [ "$dur_m" -gt 0 ]; then
      session_duration="$(printf "%dm%02ds" "$dur_m" "$dur_s")"
    else
      session_duration="$(printf "%ds" "$dur_s")"
    fi
  fi
fi

# ══════════════════════════════════════════════════════════
# 5. 运行时版本（仅在检测到项目文件时显示）
# ══════════════════════════════════════════════════════════
runtime_info=""

if [ -f "${cwd}/package.json" ] 2>/dev/null; then
  node_ver=$(node --version 2>/dev/null | sed 's/^v//')
  [ -n "$node_ver" ] && runtime_info="${runtime_info} node:${node_ver}"
fi

if [ -f "${cwd}/pyproject.toml" ] || [ -f "${cwd}/requirements.txt" ] || [ -f "${cwd}/setup.py" ] 2>/dev/null; then
  py_ver=$(python3 --version 2>/dev/null | awk '{print $2}')
  [ -n "$py_ver" ] && runtime_info="${runtime_info} py:${py_ver}"
fi

if [ -f "${cwd}/go.mod" ] 2>/dev/null; then
  go_ver=$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//')
  [ -n "$go_ver" ] && runtime_info="${runtime_info} go:${go_ver}"
fi

if [ -f "${cwd}/Cargo.toml" ] 2>/dev/null; then
  rust_ver=$(rustc --version 2>/dev/null | awk '{print $2}')
  [ -n "$rust_ver" ] && runtime_info="${runtime_info} rust:${rust_ver}"
fi

if [ -f "${cwd}/Gemfile" ] 2>/dev/null; then
  ruby_ver=$(ruby --version 2>/dev/null | awk '{print $2}')
  [ -n "$ruby_ver" ] && runtime_info="${runtime_info} ruby:${ruby_ver}"
fi

# ══════════════════════════════════════════════════════════
# 6. 颜色定义
# ══════════════════════════════════════════════════════════
# 暗色调色板，兼容浅色/白色终端主题
CYAN=$'\033[38;5;30m'
LCYAN=$'\033[38;5;31m'
YELLOW=$'\033[38;5;136m'
LYELLOW=$'\033[38;5;172m'
BLUE=$'\033[38;5;25m'
LBLUE=$'\033[38;5;26m'
GREEN=$'\033[38;5;28m'
LGREEN=$'\033[38;5;34m'
RED=$'\033[38;5;124m'
LRED=$'\033[38;5;160m'
MAGENTA=$'\033[38;5;90m'
LMAGENTA=$'\033[38;5;133m'
WHITE=$'\033[0;37m'
ORANGE=$'\033[38;5;166m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

pct_color() {
  pct=$1
  if [ "$pct" -ge 85 ] 2>/dev/null; then echo "$LRED"
  elif [ "$pct" -ge 60 ] 2>/dev/null; then echo "$LYELLOW"
  else echo "$LGREEN"
  fi
}

SEP="  "
VSEP="${DIM}│${RESET}"

# ══════════════════════════════════════════════════════════
# 7. 工具函数
# ══════════════════════════════════════════════════════════
build_bar() {
  pct=$1; width=${2:-12}
  filled=$(awk -v p="$pct" -v w="$width" 'BEGIN { printf "%d", int(p*w/100+0.5) }')
  bar=""; i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i+1 )); done
  while [ $i -lt $width  ]; do bar="${bar}░"; i=$(( i+1 )); done
  echo "$bar"
}

fmt_tok() {
  t=$1
  awk -v n="$t" 'BEGIN {
    if (n == "" || n == "null" || n == "empty") { print "--"; exit }
    if (n+0 >= 1000) printf "%.1fK", n/1000
    else print n+0
  }'
}

# ══════════════════════════════════════════════════════════
# 行 1：@ 会话标识  |  模型@版本  |  $费用
# ══════════════════════════════════════════════════════════

if [ -n "$session_name" ]; then
  line1="$(printf "${DIM}@ %s${RESET}" "$session_name")"
elif [ -n "$session_id" ]; then
  line1="$(printf "${DIM}@ %s${RESET}" "$session_id")"
else
  line1=""
fi

if [ -n "$version" ]; then
  model_str="$(printf "${BOLD}${LCYAN}%s${RESET}${DIM}@%s${RESET}" "$model_short" "$version")"
else
  model_str="$(printf "${BOLD}${LCYAN}%s${RESET}" "$model_short")"
fi

if [ -n "$line1" ]; then
  line1="${line1}${SEP}${VSEP}${SEP}${model_str}"
else
  line1="$model_str"
fi

if [ -n "$total_cost" ] && [ "$total_cost" != "empty" ]; then
  cost_fmt=$(awk -v c="$total_cost" 'BEGIN { printf "$%.2f", c }')
  line1="${line1}${SEP}${VSEP}${SEP}$(printf "${LGREEN}%s${RESET}" "$cost_fmt")"
fi

# ══════════════════════════════════════════════════════════
# 行 2：~/目录  |  ⎇ 分支  |  commit时间  |  worktree  |  电池
# ══════════════════════════════════════════════════════════
line2="$(printf "${LBLUE}%s${RESET}" "$short_cwd")"

if [ -n "$branch" ]; then
  git_str="$(printf "⎇ ${LYELLOW}%s${RESET}" "$branch")"
  [ -n "$dirty" ]        && git_str="${git_str}$(printf "${LRED}%s${RESET}" "$dirty")"
  [ -n "$ahead_behind" ] && git_str="${git_str}$(printf " ${LMAGENTA}%s${RESET}" "$ahead_behind")"
  [ -n "$stash_count" ]  && git_str="${git_str}$(printf " ${DIM}%s${RESET}" "$stash_count")"
  line2="${line2}${SEP}${VSEP}${SEP}${git_str}"
fi

if [ -n "$last_commit_rel" ]; then
  line2="${line2}${SEP}${VSEP}${SEP}$(printf "${DIM}commit: %s${RESET}" "$last_commit_rel")"
fi

if [ -n "$worktree_name" ]; then
  line2="${line2}${SEP}${VSEP}${SEP}$(printf "${ORANGE}wt:${BOLD}%s${RESET}" "$worktree_name")"
fi

if [ -n "$battery_str" ]; then
  batt_num=$(echo "$battery_str" | grep -oE '[0-9]+')
  if [ -n "$batt_num" ] && [ "$batt_num" -le 20 ] 2>/dev/null; then
    line2="${line2}${SEP}${VSEP}${SEP}$(printf "${LRED}%s${RESET}" "$battery_str")"
  elif [ -n "$batt_num" ] && [ "$batt_num" -le 50 ] 2>/dev/null; then
    line2="${line2}${SEP}${VSEP}${SEP}$(printf "${LYELLOW}%s${RESET}" "$battery_str")"
  else
    line2="${line2}${SEP}${VSEP}${SEP}$(printf "${LGREEN}%s${RESET}" "$battery_str")"
  fi
fi

# ══════════════════════════════════════════════════════════
# 行 3：上下文  |  速率限制  |  会话时长  |  Agent
# ══════════════════════════════════════════════════════════

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  bar=$(build_bar "$used_int" 12)
  bar_color=$(pct_color "$used_int")
  ctx_str="$(printf "ctx ${bar_color}%s${RESET} ${bar_color}%d%%${RESET}" "$bar" "$used_int")"
  if [ -n "$remaining" ]; then
    rem_int=$(printf '%.0f' "$remaining")
    ctx_str="${ctx_str}$(printf "${DIM}/%d%%${RESET}" "$rem_int")"
  fi
  if [ -n "$ctx_size" ] && [ "$ctx_size" != "empty" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    ctx_size_k=$(awk -v s="$ctx_size" 'BEGIN { printf "%gK", s/1000 }')
    ctx_str="${ctx_str}$(printf " ${DIM}[%s]${RESET}" "$ctx_size_k")"
  fi
  if [ -n "$in_tok" ] && [ "$in_tok" != "null" ] && [ "$in_tok" != "empty" ]; then
    in_fmt=$(fmt_tok "$in_tok")
    out_fmt=$(fmt_tok "$out_tok")
    ctx_str="${ctx_str}$(printf " ${DIM}in:%s out:%s${RESET}" "$in_fmt" "$out_fmt")"
    if [ -n "$cache_read" ] && [ "$cache_read" != "null" ] && [ "$cache_read" != "empty" ] \
       && [ "$cache_read" -gt 0 ] 2>/dev/null; then
      cache_fmt=$(fmt_tok "$cache_read")
      ctx_str="${ctx_str}$(printf " ${DIM}cache:${LGREEN}%s${RESET}" "$cache_fmt")"
    fi
  fi
else
  ctx_str="$(printf "ctx ${DIM}%s${RESET} --%%" "░░░░░░░░░░░░")"
fi
line3="$ctx_str"

rl_str=""
if [ -n "$five_pct" ]; then
  f_int=$(printf '%.0f' "$five_pct")
  f_color=$(pct_color "$f_int")
  rl_str="${rl_str}$(printf " 5h:${f_color}%d%%${RESET}" "$f_int")"
  if [ -n "$five_reset" ]; then
    now_epoch=$(date +%s)
    secs_left=$(( five_reset - now_epoch ))
    if [ "$secs_left" -gt 0 ] 2>/dev/null; then
      mins_left=$(( secs_left / 60 ))
      if [ "$mins_left" -ge 60 ]; then
        rl_str="${rl_str}$(printf "${DIM}(%dh%dm)${RESET}" "$(( mins_left/60 ))" "$(( mins_left%60 ))")"
      else
        rl_str="${rl_str}$(printf "${DIM}(%dm)${RESET}" "$mins_left")"
      fi
    fi
  fi
fi
if [ -n "$week_pct" ]; then
  w_int=$(printf '%.0f' "$week_pct")
  w_color=$(pct_color "$w_int")
  rl_str="${rl_str}$(printf " 7d:${w_color}%d%%${RESET}" "$w_int")"
fi
[ -n "$rl_str" ] && line3="${line3}${SEP}${VSEP}${rl_str}"

if [ -n "$session_duration" ]; then
  line3="${line3}${SEP}${VSEP}${SEP}$(printf "~${DIM}%s${RESET}" "$session_duration")"
fi

if [ -n "$agent_name" ]; then
  line3="${line3}${SEP}${VSEP}${SEP}$(printf "${ORANGE}agent:${BOLD}%s${RESET}" "$agent_name")"
fi

# ══════════════════════════════════════════════════════════
# 行 4：系统资源  |  Runtime  |  IP
# ══════════════════════════════════════════════════════════
cpu_color=$(pct_color "$cpu_pct")
mem_color=$(pct_color "$mem_pct")
disk_color="$LGREEN"
if [ -n "$disk_pct" ] && [ "$disk_pct" != "?" ]; then
  disk_color=$(pct_color "$disk_pct")
fi

sys_str="$(printf "CPU:${cpu_color}%s%%${RESET}" "$cpu_pct")"
[ -n "$load1" ] && sys_str="${sys_str}$(printf "${DIM}(%.2f)${RESET}" "$load1")"
sys_str="${sys_str}$(printf " Mem:${mem_color}%s/%sG${RESET}" "$mem_used_gb" "$mem_total_gb")"
sys_str="${sys_str}$(printf " Disk:${disk_color}%s%%${RESET}" "$disk_pct")"
[ -n "$uptime_str" ] && sys_str="${sys_str}$(printf " ${DIM}up %s${RESET}" "$uptime_str")"

line4="$sys_str"

if [ -n "$runtime_info" ]; then
  line4="${line4}${SEP}${VSEP}$(printf "${DIM}%s${RESET}" "$runtime_info")"
fi

if [ -n "$local_ip" ]; then
  line4="${line4}${SEP}${VSEP}${SEP}$(printf "${DIM}%s${RESET}" "$local_ip")"
fi

# ══════════════════════════════════════════════════════════
# 行 5：工具调用统计
# ══════════════════════════════════════════════════════════
bash_count=0
skill_count=0
agent_count=0
edit_count=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  bash_count=$(grep -c '"name":"Bash"' "$transcript_path" 2>/dev/null) || true
  skill_count=$(grep -c '"name":"Task"' "$transcript_path" 2>/dev/null) || true
  agent_count=$(grep -c '"name":"Agent"' "$transcript_path" 2>/dev/null) || true
  edit_count=$(grep -c '"name":"Edit"' "$transcript_path" 2>/dev/null) || true
fi
line5="Bash:${bash_count} Skill:${skill_count} Agent:${agent_count} Edit:${edit_count}"

# ══════════════════════════════════════════════════════════
# 行 6：输出风格  |  vim 模式（可选）
# ══════════════════════════════════════════════════════════
line6=""

if [ -n "$style" ] && [ "$style" != "default" ] && [ "$style" != "Default" ]; then
  style_str="$(printf "${LMAGENTA}style:%s${RESET}" "$style")"
  if [ -n "$line6" ]; then line6="${line6}${SEP}${VSEP}${SEP}${style_str}"
  else line6="$style_str"; fi
fi

if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "NORMAL" ]; then
    vim_str="$(printf "${LGREEN}N${RESET}")"
  else
    vim_str="$(printf "${LYELLOW}I${RESET}")"
  fi
  if [ -n "$line6" ]; then line6="${line6}${SEP}${VSEP}${SEP}${vim_str}"
  else line6="$vim_str"; fi
fi

# ══════════════════════════════════════════════════════════
# 输出
# ══════════════════════════════════════════════════════════
[ -n "$line1" ] && printf "%s\n" "$line1"
printf "%s\n" "$line2"
printf "%s\n%s\n" "$line3" "$line4"
printf "%s\n" "$line5"
[ -n "$line6" ] && printf "%s\n" "$line6"
exit 0
