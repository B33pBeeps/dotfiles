#!/usr/bin/env bash
# Live ripgrep through fzf with bat previews → open the match in nvim at its line.
# Type to grep file *contents* across the cwd; great for finding a function when
# you don't know the file. Runs in a tmux popup (cwd = the calling pane's dir).

set -uo pipefail

RG='rg --column --line-number --no-heading --color=always --smart-case'

sel=$(
  fzf --ansi --disabled \
      --prompt 'rg> ' \
      --reverse \
      --delimiter : \
      --bind "start:reload:$RG {q} || true" \
      --bind "change:reload:sleep 0.05; $RG {q} || true" \
      --preview 'bat --color=always --style=numbers --highlight-line {2} -- {1}' \
      --preview-window 'right,60%,+{2}+3/3,~3' \
      < /dev/null
) || exit 0

[ -z "$sel" ] && exit 0
file=$(printf '%s' "$sel" | cut -d: -f1)
line=$(printf '%s' "$sel" | cut -d: -f2)
[ -n "$file" ] && exec nvim "+${line:-1}" "$file"
