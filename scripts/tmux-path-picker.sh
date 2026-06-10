#!/usr/bin/env bash
# Scrollback path picker — "click the compiler error" for the terminal.
# Captures the calling pane's history, extracts file[:line[:col]] references
# that actually exist on disk, fzf with a bat preview pinned to the line,
# opens nvim at that line. Runs in a tmux popup (cwd = calling pane's dir).
set -uo pipefail

# Inside a popup, display-message still reports the pane underneath it
pane_id=${1:-$(tmux display-message -p '#{pane_id}')}

# Most-recent-first, deduped; trailing punctuation stripped so "draw.go:142,"
# and "(wire.go:88)" still resolve. Two shapes: anything with a slash, or a
# bare filename with an extension — both with optional :line[:col].
extract() {
  tmux capture-pane -t "$pane_id" -pJ -S -10000 \
    | grep -oE '(~|\.{1,2})?[A-Za-z0-9_@.-]*(/[A-Za-z0-9_@.-]+)+(:[0-9]+){0,2}|[A-Za-z0-9_@-]+\.[A-Za-z0-9]{1,8}(:[0-9]+){0,2}' \
    | sed -E 's/[.,;:)>"]+$//' \
    | tac | awk '!seen[$0]++' | head -n 500
}

# Validate against disk; emit "display \t file \t line" (line defaults to 1)
candidates() {
  local tok file line
  while IFS= read -r tok; do
    file=$tok line=
    if [[ $tok =~ ^(.+):([0-9]+)(:[0-9]+)?$ ]]; then
      file=${BASH_REMATCH[1]} line=${BASH_REMATCH[2]}
    fi
    file=${file/#\~/$HOME}
    [[ -f $file ]] || continue
    if [[ -n $line ]]; then
      printf '\033[33m%s\033[0m\033[1;35m:%s\033[0m\t%s\t%s\n' "$file" "$line" "$file" "$line"
    else
      printf '\033[33m%s\033[0m\t%s\t1\n' "$file" "$file"
    fi
  done < <(extract) | awk -F'\t' '!seen[$2":"$3]++'
}

list=$(candidates)
if [[ -z $list ]]; then
  read -r -n 1 -s -p "no file paths found in scrollback — press any key"
  exit 0
fi

sel=$(fzf --ansi --reverse --tiebreak=index \
  --delimiter '\t' --with-nth 1 \
  --prompt 'path> ' --pointer "▸" \
  --footer "enter: open in nvim at line" --color "footer:8" \
  --preview 'bat --color=always --style=numbers --highlight-line {3} -- {2}' \
  --preview-window 'right,60%,+{3}+3/3,~3' \
  <<< "$list") || exit 0

file=$(cut -f2 <<< "$sel")
line=$(cut -f3 <<< "$sel")
[[ -n $file ]] && exec nvim "+${line:-1}" "$file"
