#!/usr/bin/env bash
# Scrollback command picker — every command you ran (lines after the ╰─❯
# prompt marker), fzf'd. Enter COPIES (never runs); ctrl-e pastes it onto
# the originating pane's prompt for editing. Runs in a tmux popup.
set -uo pipefail

# Inside a popup, display-message still reports the pane underneath it
pane_id=${1:-$(tmux display-message -p '#{pane_id}')}

cmds=$(tmux capture-pane -t "$pane_id" -pJ -S -10000 \
  | sed -nE 's/^╰─❯ +(.+)$/\1/p' \
  | sed -E 's/[[:space:]]+$//' \
  | tac | awk 'NF && !seen[$0]++' | head -n 300)

if [[ -z $cmds ]]; then
  read -r -n 1 -s -p "no prompt commands found in scrollback — press any key"
  exit 0
fi

# "display \t raw" fields keep selection parsing independent of ANSI codes
list=$(while IFS= read -r c; do printf '\033[32m%s\033[0m\t%s\n' "$c" "$c"; done <<< "$cmds")

# --no-preview: the global FZF_DEFAULT_OPTS bat preview makes no sense here
out=$(fzf --ansi --reverse --tiebreak=index --no-preview \
  --delimiter '\t' --with-nth 1 \
  --prompt 'cmd> ' --pointer "▸" \
  --footer "enter: copy · ctrl-e: paste to prompt (no run)" --color "footer:8" \
  --expect=ctrl-e \
  <<< "$list") || exit 0

key=$(sed -n 1p <<< "$out")
cmd=$(sed -n 2p <<< "$out" | cut -f2)
[[ -z $cmd ]] && exit 0

if [[ $key == ctrl-e ]]; then
  tmux send-keys -t "$pane_id" "$cmd"        # type it, don't run it
else
  tmux set-buffer -- "$cmd"
  if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy >/dev/null; then
    printf '%s' "$cmd" | wl-copy
  elif command -v xclip >/dev/null; then
    printf '%s' "$cmd" | xclip -selection clipboard
  fi
  tmux display-message "copied: $cmd"
fi
