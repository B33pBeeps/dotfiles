#!/usr/bin/env bash
# Scrollback command picker — commands from YOUR prompt and from agent/doc
# output, fzf'd. Enter copies to the clipboard — nothing else, never runs.
# Runs in a tmux popup.
#
# Sources (color-coded):
#   green  ╰─❯ prompt lines (commands you ran)
#   cyan   "$ cmd" lines (code blocks, READMEs, agent suggestions)
#   yellow Bash(cmd) lines (Claude Code tool calls)
#   plain  any line whose first word is a real executable (code blocks
#          without a $ prefix — claude/codex output); some prose noise
#          is possible, fzf-filter past it
set -uo pipefail

# Inside a popup, display-message still reports the pane underneath it
pane_id=${1:-$(tmux display-message -p '#{pane_id}')}

# Emit "linenr <TAB> source <TAB> text"; generic candidates marked G get the
# executable check afterwards (one command -v per unique first word).
raw=$(tmux capture-pane -t "$pane_id" -pJ -S -10000 | awk '
  {
    line = $0
    if (match(line, /^╰─❯ +/)) {
      print NR "\tP\t" substr(line, RSTART + RLENGTH); next
    }
    if (match(line, /^[[:space:]]*\$ +/)) {
      print NR "\tD\t" substr(line, RSTART + RLENGTH); next
    }
    if (match(line, /Bash\(/)) {
      s = substr(line, RSTART + RLENGTH)
      sub(/\)[^)]*$/, "", s)
      if (s != "" && s !~ /…/) print NR "\tB\t" s
      next
    }
    if (match(line, /^[[:space:]]*[a-z][a-zA-Z0-9_.-]* /)) {
      t = line; sub(/^[[:space:]]+/, "", t)
      if (length(t) <= 200 && t !~ /[.:,;]$/) print NR "\tG\t" t
    }
  }')

# Keep G lines only when the first word is an executable on this machine
declare -A is_cmd
cmds=$(while IFS=$'\t' read -r nr src text; do
  [[ -z ${text// } ]] && continue
  if [[ $src == G ]]; then
    w=${text%% *}
    if [[ -z ${is_cmd[$w]:-} ]]; then
      command -v "$w" >/dev/null 2>&1 && is_cmd[$w]=y || is_cmd[$w]=n
    fi
    [[ ${is_cmd[$w]} == y ]] || continue
  fi
  printf '%s\t%s\t%s\n' "$nr" "$src" "$text"
done <<< "$raw" | sort -t$'\t' -k1,1rn | awk -F'\t' '!seen[$3]++' | head -n 400)

if [[ -z $cmds ]]; then
  read -r -n 1 -s -p "no commands found in scrollback — press any key"
  exit 0
fi

# "display \t raw" fields keep selection parsing independent of ANSI codes
list=$(while IFS=$'\t' read -r _ src text; do
  case $src in
    P) c='1;32' ;;  # your prompt — bold green
    D) c='36'   ;;  # $-prefixed — cyan
    B) c='33'   ;;  # Claude Bash() — yellow
    *) c='0'    ;;  # generic/agent output — plain
  esac
  printf '\033[%sm%s\033[0m\t%s\n' "$c" "$text" "$text"
done <<< "$cmds")

# --no-preview: the global FZF_DEFAULT_OPTS bat preview makes no sense here
out=$(fzf --ansi --reverse --tiebreak=index --no-preview \
  --delimiter '\t' --with-nth 1 \
  --prompt 'cmd> ' --pointer "▸" \
  --footer "enter: copy · green=yours cyan=\$ yellow=claude" --color "footer:8" \
  <<< "$list") || exit 0

cmd=$(cut -f2 <<< "$out")
[[ -z $cmd ]] && exit 0

# -w forwards to the system clipboard via OSC52 — no wl-copy/xclip process
# (wl-copy forks a clipboard-server child that holds the popup tty open
# and can hang the client; never spawn it from a popup)
tmux set-buffer -w -- "$cmd"
tmux display-message "copied: $cmd"
