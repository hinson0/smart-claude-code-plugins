#!/bin/bash
# Claude Code statusLine command — level 1 (minimal)
#
# Layout:
#   line 1: @ session-id  |  model@version  |  $cost
#   line 3: ctx-bar+tokens+cache  |  rate-limits(reset countdown)  |  session-duration  |  agent

input=$(cat)

# Save raw JSON for context capture (used by smart:token-log skill)
echo "$input" > "$HOME/.claude/.statusline-latest.json" 2>/dev/null

# ══════════════════════════════════════════════════════════
# 1. Extract Claude data from JSON
# ══════════════════════════════════════════════════════════
model=$(echo "$input"          | jq -r '.model.display_name // ""')
used=$(echo "$input"           | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input"      | jq -r '.context_window.remaining_percentage // empty')
ctx_size=$(echo "$input"       | jq -r '.context_window.context_window_size // empty')
in_tok=$(echo "$input"         | jq -r '.context_window.current_usage.input_tokens // empty')
out_tok=$(echo "$input"        | jq -r '.context_window.current_usage.output_tokens // empty')
cache_read=$(echo "$input"     | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
session_id=$(echo "$input"     | jq -r '.session_id // ""')
session_name=$(echo "$input"   | jq -r '.session_name // ""')
five_pct=$(echo "$input"       | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"       | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "$input"     | jq -r '.rate_limits.five_hour.resets_at // empty')
version=$(echo "$input"        | jq -r '.version // ""')
transcript_path=$(echo "$input"| jq -r '.transcript_path // ""')
agent_name=$(echo "$input"     | jq -r '.agent.name // ""')
total_cost=$(echo "$input"     | jq -r '.cost.total_cost_usd // empty')

# Short model name: "Claude Sonnet 4.6" → "Sonnet 4.6"
model_short=$(echo "$model" | sed 's/^Claude //')

# ══════════════════════════════════════════════════════════
# 2. Session duration (calculated from transcript file birth time)
# ══════════════════════════════════════════════════════════
session_duration=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  birth_ts=$(stat -f %B "$transcript_path" 2>/dev/null || echo "")
  if [ -z "$birth_ts" ] || [ "$birth_ts" = "0" ]; then
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
# 3. Color definitions
# ══════════════════════════════════════════════════════════
LCYAN=$'\033[38;5;31m'
LYELLOW=$'\033[38;5;172m'
LGREEN=$'\033[38;5;34m'
LRED=$'\033[38;5;160m'
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
# 4. Utilities
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
# line 1: @ session-id  |  model@version  |  $cost
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
# line 3: Context  |  Rate limits  |  session duration  |  Agent
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
# Output
# ══════════════════════════════════════════════════════════
[ -n "$line1" ] && printf "%s\n" "$line1"
printf "%s\n" "$line3"
exit 0
