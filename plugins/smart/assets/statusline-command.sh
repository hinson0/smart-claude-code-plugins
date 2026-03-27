#!/bin/bash
# Claude Code statusLine command — enhanced
#
# Layout:
#   line 1: [model@version]  ~/cwd  commit-time  battery
#   line G: ⎇ branch[dirty][↑↓ ahead/behind][≡stash]  wt:worktree  (git repos only)
#   line 2: ctx-bar+tokens+cache  |  rate-limits(reset countdown)  |  session-duration  |  agent
#   line 3: CPU(load)  Mem  Disk  uptime  |  Runtime(Node/Py/Go/Rust/Ruby)  |  local-IP
#   line 4: session-id  |  output-style  |  vim-mode  |  tool-call-stats

input=$(cat)

# ══════════════════════════════════════════════════════════
# 1. Extract Claude data from JSON
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

# Short model name: "Claude Sonnet 4.6" → "Sonnet 4.6"
model_short=$(echo "$model" | sed 's/^Claude //')

# Directory: shorten home to ~, keep last 2 segments if >40 chars
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")
short_cwd_len=$(echo -n "$short_cwd" | wc -c | tr -d ' ')
if [ "$short_cwd_len" -gt 40 ] 2>/dev/null; then
  short_cwd="…/$(echo "$short_cwd" | awk -F/ '{print $(NF-1)"/"$NF}')"
fi

# ══════════════════════════════════════════════════════════
# 2. Git info (skip optional locks to avoid blocking)
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

  # dirty check (unstaged or staged changes)
  if ! GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --quiet 2>/dev/null \
    || ! GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    dirty="*"
  fi

  # untracked files
  if [ -n "$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
    dirty="${dirty}?"
  fi

  # ahead / behind remote
  upstream=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
  if [ -n "$upstream" ]; then
    ahead=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "0")
    behind=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")
    ab=""
    [ "$ahead"  -gt 0 ] && ab="${ab}↑${ahead}"
    [ "$behind" -gt 0 ] && ab="${ab}↓${behind}"
    [ -n "$ab" ] && ahead_behind="$ab"
  fi

  # stash count
  sc=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  [ "$sc" -gt 0 ] 2>/dev/null && stash_count="≡${sc}"

  # last commit relative time (compact format)
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
# 3. System info (macOS)
# ══════════════════════════════════════════════════════════

# -- CPU (1-min load / cores) → approximate percentage
cpu_cores=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)
load1=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
cpu_pct=$(awk -v l="$load1" -v c="$cpu_cores" \
  'BEGIN { v = l/c*100; if(v>100) v=100; printf "%.0f", v }' 2>/dev/null || echo "?")

# -- Memory (used / total, GB)
mem_info=$(vm_stat 2>/dev/null)
page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
mem_total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
mem_total_gb=$(awk -v b="$mem_total_bytes" 'BEGIN { printf "%.0f", b/1073741824 }')

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

# -- Disk (volume containing cwd, used %)
if [ -n "$cwd" ]; then
  disk_info=$(df -h "$cwd" 2>/dev/null | tail -1)
  disk_used=$(echo "$disk_info" | awk '{print $3}')
  disk_total=$(echo "$disk_info" | awk '{print $2}')
  disk_pct=$(echo "$disk_info"  | awk '{gsub(/%/,"",$5); print $5}')
else
  disk_used="?"; disk_total="?"; disk_pct="?"
fi

# -- Uptime (compact)
uptime_str=$(uptime 2>/dev/null | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' \
  | sed 's/^ *//' | sed 's/  */ /g')

# -- Battery (macOS pmset)
battery_str=""
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

# -- Local IP (first non-loopback IPv4)
local_ip=$(ipconfig getifaddr en0 2>/dev/null \
  || ipconfig getifaddr en1 2>/dev/null \
  || echo "")

# ══════════════════════════════════════════════════════════
# 4. Session duration (calculated from transcript file birth time)
# ══════════════════════════════════════════════════════════
session_duration=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # macOS: stat -f %B gets file birth time in seconds
  birth_ts=$(stat -f %B "$transcript_path" 2>/dev/null || echo "")
  if [ -z "$birth_ts" ] || [ "$birth_ts" = "0" ]; then
    # fallback: use file modification time
    birth_ts=$(stat -f %m "$transcript_path" 2>/dev/null || echo "")
  fi
  if [ -n "$birth_ts" ]; then
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
# 5. Runtime versions (shown only when project file detected)
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
# 6. Color definitions
# ══════════════════════════════════════════════════════════
# Dark palette, compatible with light/white terminal themes
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
# 7. Utilities
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
# line 1: model  |  cwd  |  commit-time  |  battery
# line G: ⎇ branch  |  worktree  (git repos only)
# ══════════════════════════════════════════════════════════

if [ -n "$version" ]; then
  line1="$(printf "${BOLD}${LCYAN}%s${RESET}${DIM}@%s${RESET}" "$model_short" "$version")"
else
  line1="$(printf "${BOLD}${LCYAN}%s${RESET}" "$model_short")"
fi

# Git dedicated line
git_line=""
if [ -n "$branch" ]; then
  git_str="$(printf "⎇ ${LYELLOW}%s${RESET}" "$branch")"
  [ -n "$dirty" ]        && git_str="${git_str}$(printf "${LRED}%s${RESET}" "$dirty")"
  [ -n "$ahead_behind" ] && git_str="${git_str}$(printf " ${LMAGENTA}%s${RESET}" "$ahead_behind")"
  [ -n "$stash_count" ]  && git_str="${git_str}$(printf " ${DIM}%s${RESET}" "$stash_count")"
  git_line="$git_str"
fi

if [ -n "$worktree_name" ]; then
  wt_str="$(printf "${ORANGE}wt:${BOLD}%s${RESET}" "$worktree_name")"
  # only show branch in parens when it differs from worktree name
  if [ -n "$worktree_branch" ] && [ "$worktree_branch" != "$worktree_name" ]; then
    wt_str="${wt_str}$(printf "${DIM}(%s)${RESET}" "$worktree_branch")"
  fi
  if [ -n "$git_line" ]; then
    git_line="${git_line}${SEP}${VSEP}${SEP}${wt_str}"
  else
    git_line="$wt_str"
  fi
fi

line1="${line1}${SEP}${VSEP}${SEP}$(printf "${LBLUE}%s${RESET}" "$short_cwd")"

if [ -n "$last_commit_rel" ]; then
  line1="${line1}${SEP}${VSEP}${SEP}$(printf "${DIM}commit: %s${RESET}" "$last_commit_rel")"
fi

if [ -n "$battery_str" ]; then
  batt_num=$(echo "$battery_str" | grep -oE '[0-9]+')
  if [ -n "$batt_num" ] && [ "$batt_num" -le 20 ] 2>/dev/null; then
    line1="${line1}${SEP}${VSEP}${SEP}$(printf "${LRED}%s${RESET}" "$battery_str")"
  elif [ -n "$batt_num" ] && [ "$batt_num" -le 50 ] 2>/dev/null; then
    line1="${line1}${SEP}${VSEP}${SEP}$(printf "${LYELLOW}%s${RESET}" "$battery_str")"
  else
    line1="${line1}${SEP}${VSEP}${SEP}$(printf "${LGREEN}%s${RESET}" "$battery_str")"
  fi
fi

# ══════════════════════════════════════════════════════════
# line 2: Context  |  Rate limits  |  session duration  |  Agent
# ══════════════════════════════════════════════════════════

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  bar=$(build_bar "$used_int" 12)
  bar_color=$(pct_color "$used_int")
  # show used% and remaining%
  ctx_str="$(printf "ctx ${bar_color}%s${RESET} ${bar_color}%d%%${RESET}" "$bar" "$used_int")"
  if [ -n "$remaining" ]; then
    rem_int=$(printf '%.0f' "$remaining")
    ctx_str="${ctx_str}$(printf "${DIM}/%d%%${RESET}" "$rem_int")"
  fi
  # show context window size in K
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
line2="$ctx_str"

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
[ -n "$rl_str" ] && line2="${line2}${SEP}${VSEP}${rl_str}"

if [ -n "$session_duration" ]; then
  line2="${line2}${SEP}${VSEP}${SEP}$(printf "~${DIM}%s${RESET}" "$session_duration")"
fi

if [ -n "$agent_name" ]; then
  line2="${line2}${SEP}${VSEP}${SEP}$(printf "${ORANGE}agent:${BOLD}%s${RESET}" "$agent_name")"
fi

# ══════════════════════════════════════════════════════════
# line 3: System resources  |  Runtime  |  IP
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

line3="$sys_str"

if [ -n "$runtime_info" ]; then
  line3="${line3}${SEP}${VSEP}$(printf "${DIM}%s${RESET}" "$runtime_info")"
fi

if [ -n "$local_ip" ]; then
  line3="${line3}${SEP}${VSEP}${SEP}$(printf "${DIM}%s${RESET}" "$local_ip")"
fi

# ══════════════════════════════════════════════════════════
# line 4: session ID
# line 5: output style  |  vim mode
# line 6: tool call stats
# ══════════════════════════════════════════════════════════

# line 4: session ID
if [ -n "$session_name" ]; then
  line4="$(printf "${DIM}@ %s${RESET}" "$session_name")"
elif [ -n "$session_id" ]; then
  line4="$(printf "${DIM}@ %s${RESET}" "$session_id")"
else
  line4=""
fi

# line 5: output style | vim mode
line5=""

if [ -n "$style" ] && [ "$style" != "default" ] && [ "$style" != "Default" ]; then
  style_str="$(printf "${LMAGENTA}style:%s${RESET}" "$style")"
  if [ -n "$line5" ]; then line5="${line5}${SEP}${VSEP}${SEP}${style_str}"
  else line5="$style_str"; fi
fi

if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "NORMAL" ]; then
    vim_str="$(printf "${LGREEN}N${RESET}")"
  else
    vim_str="$(printf "${LYELLOW}I${RESET}")"
  fi
  if [ -n "$line5" ]; then line5="${line5}${SEP}${VSEP}${SEP}${vim_str}"
  else line5="$vim_str"; fi
fi

# line 6: tool call stats (parsed from transcript, always shown)
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
line6="Bash:${bash_count} Skill:${skill_count} Agent:${agent_count} Edit:${edit_count}"

# ══════════════════════════════════════════════════════════
# Output
# ══════════════════════════════════════════════════════════
printf "%s\n" "$line1"
[ -n "$git_line" ] && printf "%s\n" "$git_line"
printf "%s\n%s\n" "$line2" "$line3"
[ -n "$line4" ] && printf "%s\n" "$line4"
printf "%s\n" "$line6"
[ -n "$line5" ] && printf "%s\n" "$line5"
exit 0
