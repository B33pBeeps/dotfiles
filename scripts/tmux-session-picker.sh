#!/usr/bin/env bash
# Simple fzf session picker — colored, 1-9 quick switch.
set -e

current=$(tmux display-message -p '#S')

list_sessions() {
  local i=1
  tmux list-sessions -F '#S|#{session_windows}|#{pane_current_path}' 2>/dev/null | while IFS='|' read -r name wins path; do
    path="${path/#$HOME/\~}"
    if [[ "$name" == "$current" ]]; then
      printf "\033[1;35m%d\033[0m  \033[1;32m▸ %s\033[0m\n" "$i" "$name"
    else
      printf "\033[1;35m%d\033[0m    \033[33m%s\033[0m\n" "$i" "$name"
    fi
    i=$((i + 1))
  done
}

result=$(
  list_sessions | fzf \
    --ansi \
    --reverse \
    --no-sort \
    --no-preview \
    --pointer "▸" \
    --prompt " " \
    --expect=1,2,3,4,5,6,7,8,9
) || exit 0

key=$(head -1 <<< "$result")
selected=$(tail -1 <<< "$result")

if [[ -n "$key" && "$key" =~ ^[1-9]$ ]]; then
  name=$(tmux list-sessions -F '#S' 2>/dev/null | sed -n "${key}p")
else
  name=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g; s/^[0-9]*  [▸ ]*//' | awk '{print $1}')
fi

[[ -n "$name" && "$name" != "$current" ]] && tmux switch-client -t "$name"
