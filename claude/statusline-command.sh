#!/usr/bin/env bash
# Claude Code status line script
# Styled to complement Powerlevel10k

input=$(cat)

# Extract fields from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Shorten home directory
cwd="${cwd/#$HOME/~}"

# --- Build status line segments ---

# user@host:dir  (green/blue, matching classic bash style)
printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' \
  "$(whoami)" "$(hostname -s)" "$cwd"

# git branch + ahead/behind (skip optional locks to avoid hangs)
if git -C "${cwd/#\~/$HOME}" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "${cwd/#\~/$HOME}" \
    --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "${cwd/#\~/$HOME}" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Try to get ahead/behind counts; skip silently if no upstream
    ab=$(git -C "${cwd/#\~/$HOME}" --no-optional-locks rev-list \
      --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [ -n "$ab" ]; then
      ahead=$(echo "$ab" | awk '{print $1}')
      behind=$(echo "$ab" | awk '{print $2}')
      ab_str=""
      [ "$ahead" -gt 0 ] 2>/dev/null && ab_str="${ab_str}↑${ahead}"
      [ "$behind" -gt 0 ] 2>/dev/null && ab_str="${ab_str}↓${behind}"
      if [ -n "$ab_str" ]; then
        printf ' \033[90m(%s %s)\033[00m' "$branch" "$ab_str"
      else
        printf ' \033[90m(%s)\033[00m' "$branch"
      fi
    else
      printf ' \033[90m(%s)\033[00m' "$branch"
    fi
  fi
fi

# model name
[ -n "$model" ] && printf ' \033[90m[%s]\033[00m' "$model"

# context usage: percentage + raw token counts
if [ -n "$used_pct" ]; then
  # Color: green < 50%, yellow 50-80%, red > 80%
  pct_int=${used_pct%.*}
  if [ "$pct_int" -ge 80 ] 2>/dev/null; then
    color='\033[31m'   # red
  elif [ "$pct_int" -ge 50 ] 2>/dev/null; then
    color='\033[33m'   # yellow
  else
    color='\033[32m'   # green
  fi
  printf " ${color}ctx:%.0f%%\033[00m" "$used_pct"
fi

# raw token counts (e.g. 24k/200k)
if [ -n "$input_tokens" ] && [ -n "$ctx_size" ]; then
  tok_used=$(echo "$input_tokens" | awk '{
    if ($1 >= 1000) printf "%dk", int($1/1000 + 0.5)
    else printf "%d", $1
  }')
  tok_total=$(echo "$ctx_size" | awk '{
    if ($1 >= 1000) printf "%dk", int($1/1000 + 0.5)
    else printf "%d", $1
  }')
  printf ' \033[90m(%s/%s)\033[00m' "$tok_used" "$tok_total"
fi

# session cost
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ] && [ "$cost_usd" != "0.0" ]; then
  cost_fmt=$(printf "%.3f" "$cost_usd" 2>/dev/null)
  [ -n "$cost_fmt" ] && printf ' \033[90m$%s\033[00m' "$cost_fmt"
fi

# session name
[ -n "$session_name" ] && printf ' \033[90m"%s"\033[00m' "$session_name"

# vim mode
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    NORMAL) printf ' \033[33m[N]\033[00m' ;;
    INSERT) printf ' \033[32m[I]\033[00m' ;;
    *)      printf ' \033[90m[%s]\033[00m' "$vim_mode" ;;
  esac
fi

# current time HH:MM
printf ' \033[90m%s\033[00m' "$(date +%H:%M)"
