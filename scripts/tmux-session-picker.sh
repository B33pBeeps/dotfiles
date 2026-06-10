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
    --print-query \
    --footer "1-9: jump · ctrl-n: new session named <query>" --color "footer:8" \
    --expect=1,2,3,4,5,6,7,8,9,ctrl-n
) || exit 0

# --print-query layout: line 1 = query, line 2 = key, line 3 = selection (if any)
query=$(sed -n 1p <<< "$result")
key=$(sed -n 2p <<< "$result")
selected=$(sed -n 3p <<< "$result")

if [[ "$key" == "ctrl-n" ]]; then
  name=$(printf '%s' "$query" | tr ':. ' '___')
  [[ -z "$name" ]] && exit 0
  tmux has-session -t "=$name" 2>/dev/null || tmux new-session -ds "$name" -c "$HOME"
  tmux switch-client -t "=$name"
  exit 0
fi

if [[ -n "$key" && "$key" =~ ^[1-9]$ ]]; then
  name=$(tmux list-sessions -F '#S' 2>/dev/null | sed -n "${key}p")
else
  name=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g; s/^[0-9]*  [▸ ]*//' | awk '{print $1}')
fi

[[ -n "$name" && "$name" != "$current" ]] && tmux switch-client -t "$name"
