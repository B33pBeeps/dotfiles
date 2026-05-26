#!/usr/bin/env bash
# Indented tree picker — sessions + windows, colored, 1-9 quick switch sessions.
set -e

current_session=$(tmux display-message -p '#S')

build_tree() {
  local n=1
  tmux list-sessions -F '#S' 2>/dev/null | while read -r sess; do
    local smark=" "
    [[ "$sess" == "$current_session" ]] && smark="▸"
    printf "\033[1;35m%d\033[0m %s \033[1;33m%s\033[0m\n" "$n" "$smark" "$sess"
    n=$((n + 1))
    tmux list-windows -t "$sess" -F '#I|#W|#{pane_current_path}|#{window_active}' 2>/dev/null | while IFS='|' read -r idx wname path active; do
      path="${path/#$HOME/\~}"
      local wmark="  "
      [[ "$sess" == "$current_session" && "$active" == "1" ]] && wmark="▸ "
      printf "     %s\033[32m%s\033[0m:\033[36m%s\033[0m\n" "$wmark" "$idx" "$wname"
    done
  done
}

result=$(
  build_tree | fzf \
    --ansi \
    --reverse \
    --no-sort \
    --no-preview \
    --pointer " " \
    --prompt " " \
    --expect=1,2,3,4,5,6,7,8,9
) || exit 0

key=$(head -1 <<< "$result")
selected=$(tail -1 <<< "$result")

if [[ -n "$key" && "$key" =~ ^[1-9]$ ]]; then
  name=$(tmux list-sessions -F '#S' 2>/dev/null | sed -n "${key}p")
  [[ -n "$name" ]] && tmux switch-client -t "$name"
else
  clean=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g')
  if echo "$clean" | grep -qE '^\s{4,}'; then
    # Window line — find parent session + window index
    all_clean=$(build_tree | sed 's/\x1b\[[0-9;]*m//g')
    line_num=$(echo "$all_clean" | grep -nF "$(echo "$clean" | sed 's/^ *//')" | head -1 | cut -d: -f1)
    sess=$(echo "$all_clean" | head -n "$line_num" | grep -E '^[0-9]' | tail -1 | awk '{print $NF}')
    widx=$(echo "$clean" | sed 's/^[▸ ]*//' | awk -F: '{print $1}' | tr -d ' ')
    [[ -n "$sess" && -n "$widx" ]] && tmux switch-client -t "${sess}:${widx}"
  else
    # Session line
    name=$(echo "$clean" | awk '{print $NF}')
    [[ -n "$name" ]] && tmux switch-client -t "$name"
  fi
fi
