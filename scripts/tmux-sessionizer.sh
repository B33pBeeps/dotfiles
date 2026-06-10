#!/usr/bin/env bash
# tmux project sessionizer — fzf over ~/code projects (+ zoxide frecency),
# then create-or-switch a session named after the dir. Bound to prefix o.
set -e

CODE_ROOT="$HOME/code"
FD=$(command -v fd || command -v fdfind || true)   # server PATH may lack ~/.local/bin

session_name() { basename "$1" | tr ':. ' '___'; }  # tmux forbids : and .

# zoxide frecency hits under ~/code first (any depth — monorepo subdirs become
# sessions too), then the depth-2 project universe; dedup keeps first.
list_dirs() {
  {
    command -v zoxide >/dev/null && \
      zoxide query -l 2>/dev/null | awk -v root="$CODE_ROOT/" 'index($0, root) == 1'
    if [[ -n $FD ]]; then
      "$FD" --type d --min-depth 1 --max-depth 2 . "$CODE_ROOT"
    else
      find "$CODE_ROOT" -mindepth 1 -maxdepth 2 -type d -not -name '.*' 2>/dev/null
    fi
  } | sed 's:/*$::' | awk '!seen[$0]++'
}

# Lines: "<colored display>\t<raw path>". Existing-session dirs get bold-green ▸
# (same palette as tmux-session-picker.sh).
render() {
  local sessions dir disp
  sessions=$(tmux list-sessions -F '#S' 2>/dev/null || true)
  while IFS= read -r dir; do
    [[ -d $dir ]] || continue
    disp="${dir/#$HOME/\~}"
    if grep -qxF "$(session_name "$dir")" <<< "$sessions"; then
      printf '\033[1;32m▸ %s\033[0m\t%s\n' "$disp" "$dir"
    else
      printf '  \033[33m%s\033[0m\t%s\n' "$disp" "$dir"
    fi
  done < <(list_dirs)
}

sel=$(render | fzf \
  --ansi --reverse --tiebreak=index \
  --delimiter '\t' --with-nth 1 \
  --pointer "▸" --prompt " " \
  --footer "enter: create-or-switch session" --color "footer:8" \
  --preview 'eza -1 --color=always --icons {2} 2>/dev/null || ls -1 {2}' \
  --preview-window 'right:40%') || exit 0

dir=$(cut -f2 <<< "$sel")
[[ -d $dir ]] || exit 0
name=$(session_name "$dir")
tmux has-session -t "=$name" 2>/dev/null || tmux new-session -ds "$name" -c "$dir"
if [[ -n ${TMUX:-} ]]; then tmux switch-client -t "=$name"; else tmux attach -t "=$name"; fi
