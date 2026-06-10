#!/usr/bin/env bash
# Scrollback URL picker — capture the calling pane's history, fzf every URL
# (capture -J re-joins tmux-wrapped lines, so long URLs come back intact),
# enter opens in the browser, ctrl-y copies. Runs in a tmux popup.
set -uo pipefail

# Inside a popup, display-message still reports the pane underneath it
pane_id=${1:-$(tmux display-message -p '#{pane_id}')}

# In a POSIX bracket expression a literal ] must come first in the class
url_re="(https?|file)://[^][:space:]\"'<>)\\]+"
urls=$(tmux capture-pane -t "$pane_id" -pJ -S -10000 \
  | grep -oE "$url_re" \
  | sed -E 's/[.,;:!?]+$//' \
  | tac | awk '!seen[$0]++' | head -n 200)

if [[ -z $urls ]]; then
  read -r -n 1 -s -p "no URLs found in scrollback — press any key"
  exit 0
fi

# "display \t raw" fields keep selection parsing independent of ANSI codes
list=$(while IFS= read -r u; do printf '\033[36m%s\033[0m\t%s\n' "$u" "$u"; done <<< "$urls")

# --no-preview: the global FZF_DEFAULT_OPTS bat preview makes no sense for URLs
out=$(fzf --ansi --reverse --tiebreak=index --no-preview \
  --delimiter '\t' --with-nth 1 \
  --prompt 'url> ' --pointer "▸" \
  --footer "enter: open · ctrl-y: copy" --color "footer:8" \
  --expect=ctrl-y \
  <<< "$list") || exit 0

key=$(sed -n 1p <<< "$out")
url=$(sed -n 2p <<< "$out" | cut -f2)
[[ -z $url ]] && exit 0

if [[ $key == ctrl-y ]]; then
  # -w forwards to the system clipboard via OSC52 — no wl-copy/xclip process
  # (wl-copy's forked clipboard server holds the popup tty open and hangs it)
  tmux set-buffer -w -- "$url"
  tmux display-message "copied: $url"
else
  opener=$(command -v xdg-open || command -v open) || exit 0
  if command -v setsid >/dev/null; then
    setsid -f "$opener" "$url" >/dev/null 2>&1
  else
    nohup "$opener" "$url" >/dev/null 2>&1 &
  fi
fi
