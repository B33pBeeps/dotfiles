#!/usr/bin/env bash
# nock — pinned shell-command palette for tmux.
#
# The notch where an arrow meets the string: pin commands, then fire them
# into the pane you came from. Two scopes: global (everywhere) + session.
#
# Dispatch: menu <pane_id> <session> | add <session> | render <session> | delete <line>
#
# Storage: ~/.config/nock/{global.list,sessions/<safe>.list}  (one command per line)

set -e

SELF="$HOME/code/personal/dotfiles/scripts/nock.sh"
ROOT="$HOME/.config/nock"
GLOBAL="$ROOT/global.list"

# Sanitize a session name into a safe filename
safe_name() { printf '%s' "$1" | tr -c '[:alnum:]._-' '_'; }

session_file() { printf '%s/sessions/%s.list' "$ROOT" "$(safe_name "$1")"; }

ensure_store() {
  mkdir -p "$ROOT/sessions"
  [[ -f $GLOBAL ]] || : > "$GLOBAL"
}

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

# ─── render: emit the colored, numbered list ─────────────────────────
# Populates the global ENTRIES array (index → "scope\tcommand") when sourced
# via the menu path. When called as a subcommand it just prints.
render_list() {
  local session="$1"
  local sfile; sfile=$(session_file "$session")
  local n=1 cmd

  printf "\033[1;35m \033[0m \033[1;33mglobal\033[0m\n"
  if [[ -s $GLOBAL ]]; then
    while IFS= read -r cmd; do
      [[ -z $cmd ]] && continue
      printf "\033[1;35m%d\033[0m  \033[36m%s\033[0m\n" "$n" "$cmd"
      n=$((n + 1))
    done < "$GLOBAL"
  else
    printf "   \033[90m(empty — prefix+A to pin)\033[0m\n"
  fi

  printf "\033[1;35m \033[0m \033[1;33msession: %s\033[0m\n" "$session"
  if [[ -s $sfile ]]; then
    while IFS= read -r cmd; do
      [[ -z $cmd ]] && continue
      printf "\033[1;35m%d\033[0m  \033[36m%s\033[0m\n" "$n" "$cmd"
      n=$((n + 1))
    done < "$sfile"
  else
    printf "   \033[90m(empty — prefix+A to pin)\033[0m\n"
  fi
}

# Extract the raw command from a chosen fzf line (strip ANSI + leading "N  ")
line_to_cmd() {
  echo "$1" | strip_ansi | sed -E 's/^[0-9]+  //'
}

# ─── menu: the harpoon popup ─────────────────────────────────────────
cmd_menu() {
  local pane_id="$1" session="$2"
  ensure_store

  local result key selected cmd
  result=$(
    render_list "$session" | fzf \
      --ansi \
      --reverse \
      --no-sort \
      --no-preview \
      --pointer "▸" \
      --prompt " " \
      --header "enter: run · ctrl-p: paste · ctrl-d: delete · ctrl-e/g: edit" \
      --expect=1,2,3,4,5,6,7,8,9,ctrl-p \
      --bind "ctrl-d:execute-silent($SELF delete {})+reload($SELF render '$session')" \
      --bind "ctrl-e:execute(\${EDITOR:-nvim} $(session_file "$session"))+reload($SELF render '$session')" \
      --bind "ctrl-g:execute(\${EDITOR:-nvim} $GLOBAL)+reload($SELF render '$session')"
  ) || exit 0

  key=$(head -1 <<< "$result")
  selected=$(tail -1 <<< "$result")

  # Resolve which command line: a digit key picks the Nth entry directly
  if [[ "$key" =~ ^[1-9]$ ]]; then
    # Nth real entry across global+session (skip headers/empties)
    cmd=$(render_list "$session" | strip_ansi | grep -E '^[0-9]+  ' | sed -n "${key}p" | sed -E 's/^[0-9]+  //')
  else
    # Header/empty lines have no leading number — ignore them
    echo "$selected" | strip_ansi | grep -qE '^[0-9]+  ' || exit 0
    cmd=$(line_to_cmd "$selected")
  fi

  [[ -z $cmd ]] && exit 0

  if [[ "$key" == "ctrl-p" ]]; then
    tmux send-keys -t "$pane_id" "$cmd"          # paste only
  else
    tmux send-keys -t "$pane_id" "$cmd" Enter    # execute
  fi
}

# ─── add: pin command(s) from history or free-type ───────────────────
cmd_add() {
  local session="$1"
  ensure_store

  local picks query selections
  # History: strip EXTENDED_HISTORY prefix, recent-first, dedup
  picks=$(
    tac "$HOME/.zsh_history" 2>/dev/null \
      | sed 's/^: [0-9]*:[0-9]*;//' \
      | awk '!seen[$0]++' \
      | fzf --multi --print-query --prompt "pin> " \
            --header "TAB mark multiple · type a new command · enter confirm" \
            --reverse
  ) || exit 0

  # First line is the typed query; remaining lines are marked selections.
  query=$(head -1 <<< "$picks")
  selections=$(tail -n +2 <<< "$picks")

  # Combined command list (query first if it's not already a selection)
  local -a cmds=()
  if [[ -n $query ]] && ! grep -qxF "$query" <<< "$selections"; then
    cmds+=("$query")
  fi
  while IFS= read -r line; do
    [[ -n $line ]] && cmds+=("$line")
  done <<< "$selections"

  [[ ${#cmds[@]} -eq 0 ]] && exit 0

  # Scope picker
  local scope target
  scope=$(printf "session: %s\nglobal" "$session" | fzf --prompt "scope> " --reverse --no-sort) || exit 0
  if [[ $scope == global ]]; then
    target="$GLOBAL"
  else
    target=$(session_file "$session")
  fi

  local c
  for c in "${cmds[@]}"; do
    # Avoid duplicates
    grep -qxF "$c" "$target" 2>/dev/null || printf '%s\n' "$c" >> "$target"
  done

  tmux display-message "nock: pinned ${#cmds[@]} command(s) to ${scope%%:*}"
}

# ─── delete: remove a command line from session, else global ─────────
cmd_delete() {
  local line="$1" session="${2:-}"
  local cmd; cmd=$(line_to_cmd "$line")
  [[ -z $cmd ]] && exit 0

  # We don't know scope from the line alone; remove from whichever file has it.
  # Prefer session files (more specific), then global.
  local f tmp
  for f in "$ROOT"/sessions/*.list "$GLOBAL"; do
    [[ -f $f ]] || continue
    if grep -qxF "$cmd" "$f"; then
      tmp=$(mktemp)
      grep -vxF "$cmd" "$f" > "$tmp" && mv "$tmp" "$f"
      break
    fi
  done
}

# ─── dispatch ────────────────────────────────────────────────────────
case "${1:-}" in
  menu)   cmd_menu "$2" "$3" ;;
  add)    cmd_add "$2" ;;
  render) ensure_store; render_list "$2" ;;
  delete) cmd_delete "$2" "$3" ;;
  *) echo "usage: $0 menu <pane_id> <session> | add <session> | render <session> | delete <line>" >&2; exit 1 ;;
esac
