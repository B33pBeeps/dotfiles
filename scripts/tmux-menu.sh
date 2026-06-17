#!/usr/bin/env bash
# Nested tmux cheat sheet — a which-key-style menu tree, single source of truth.
# `bind ?` opens `root`; each category drills into a submenu; ← back (BSpace)
# returns to root; Esc/q closes. `bind m` jumps straight to the music submenu.
# Set TMUX_MENU_DRY=1 to print the display-menu args instead of rendering.
#
# Item colors match the popup border coding (find=teal, tools=green,
# markdown=orange, nock=yellow, music=purple, panes/windows=grey,
# sessions=aqua, config=paper). Item keys ARE the real global keybindings.
set -u

D="$HOME/code/personal/dotfiles"
self="$D/scripts/tmux-menu.sh"
PL="playerctl --player='chromium,firefox,chrome,brave,zen'"
BACK_KEY="BSpace"
BACK_LABEL="#[fg=#7c6f64]← back"

nav() { printf 'run-shell "%s %s"' "$self" "$1"; }

show() {
  local title="$1"; shift
  if [[ -n ${TMUX_MENU_DRY:-} ]]; then
    printf '== %s ==\n' "$title"
    local i=1; for a in "$@"; do printf '%2d [%s]\n' "$i" "$a"; ((i++)); done
    return
  fi
  tmux display-menu -x R -y S -T "$title" "$@"
}

case "${1:-root}" in
root)
  show "#[fg=#7daea3,bold] keybindings" \
    "" \
    "#[fg=#7daea3]find"     f "$(nav find)" \
    "#[fg=#a9b665]tools"    t "$(nav tools)" \
    "#[fg=#e78a4e]markdown" d "$(nav markdown)" \
    "#[fg=#d8a657]nock"     n "$(nav nock)" \
    "#[fg=#d3869b]music"    m "$(nav music)" \
    "#[fg=#a89984]panes"    p "$(nav panes)" \
    "#[fg=#a89984]windows"  w "$(nav windows)" \
    "#[fg=#89b482]sessions" s "$(nav sessions)" \
    "#[fg=#d4be98]config"   c "$(nav config)"
  ;;

find)
  show "#[fg=#7daea3,bold] find" \
    "" \
    "#[fg=#7daea3]find file → nvim"    f "display-popup -E -w 90% -h 85% -d \"#{pane_current_path}\" \"fzf --preview 'bat --style=numbers --color=always {}' | xargs -r nvim\"" \
    "#[fg=#7daea3]live grep → nvim"    / "display-popup -E -w 90% -h 85% -d \"#{pane_current_path}\" \"zsh -ic '$D/scripts/rg-nvim.sh'\"" \
    "#[fg=#7daea3]scrollback paths"    . "display-popup -E -w 90% -h 85% -d \"#{pane_current_path}\" \"$D/scripts/tmux-path-picker.sh\"" \
    "#[fg=#7daea3]scrollback urls"     y "display-popup -E -w 75% -h 50% \"$D/scripts/tmux-url-picker.sh\"" \
    "#[fg=#7daea3]scrollback commands" Y "display-popup -E -w 75% -h 50% \"$D/scripts/tmux-cmd-picker.sh\"" \
    "#[fg=#7daea3]elio file manager"   F "display-popup -E -w 90% -h 85% -d \"#{pane_current_path}\" \"zsh -ic 'elio'\"" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

tools)
  show "#[fg=#a9b665,bold] tools" \
    "" \
    "#[fg=#a9b665]trawl (urls/paths/cmds/plans)" G "display-popup -E -w 80% -h 70% -d \"#{pane_current_path}\" \"zsh -ic 'trawl'\"" \
    "#[fg=#a9b665]lazygit"          g "display-popup -E -S \"fg=#a9b665\" -w 90% -h 85% -d \"#{pane_current_path}\" \"lazygit\"" \
    "#[fg=#a9b665]terminal"         t "display-popup -E -w 60% -h 60% -d \"#{pane_current_path}\" \"zsh -l\"" \
    "#[fg=#a9b665]btop"             b "display-popup -E -S \"fg=#e78a4e\" -w 80% -h 70% \"btop\"" \
    "#[fg=#a9b665]redthread"        e "display-popup -E -S \"fg=#ea6962\" -w 85% -h 80% -d \"#{pane_current_path}\" \"zsh -ic 'redthread'\"" \
    "#[fg=#a9b665]claude/codex quota" q "display-popup -E -w 45% -h 45% -y 1 \"$D/scripts/tmux-quota.sh\"" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

markdown)
  show "#[fg=#e78a4e,bold] markdown" \
    "" \
    "#[fg=#e78a4e]glow browser"     n "display-popup -E -w 80% -h 70% -d \"#{pane_current_path}\" \"glow\"" \
    "#[fg=#e78a4e]project notes"    N "display-popup -E -S \"fg=#d4be98\" -w 80% -h 80% \"$D/scripts/tmux-notes.sh\"" \
    "#[fg=#e78a4e]present slides"   P "display-popup -E -w 80% -h 80% -d \"#{pane_current_path}\" \"zsh -ic 'fd -e md | fzf --reverse --preview \\\"bat --color=always --style=plain {}\\\" | xargs -r $D/scripts/slides-auto.sh'\"" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

nock)
  show "#[fg=#d8a657,bold] nock" \
    "" \
    "#[fg=#d8a657]run pinned"       a "display-popup -E -S \"fg=#d8a657\" -w 60% -h 60% \"$D/scripts/nock.sh menu\"" \
    "#[fg=#d8a657]pin command(s)"   A "display-popup -E -S \"fg=#d8a657\" -w 70% -h 70% \"$D/scripts/nock.sh add\"" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

music)
  show "#[fg=#d3869b,bold] music" \
    "" \
    "#[fg=#d3869b]play / pause"     p "run-shell \"$PL play-pause\"" \
    "#[fg=#d3869b]next"             n "run-shell \"$PL next\"" \
    "#[fg=#d3869b]previous"         b "run-shell \"$PL previous\"" \
    "#[fg=#d3869b]vol +5"           = "run-shell \"$PL volume 0.05+\"" \
    "#[fg=#d3869b]vol -5"           - "run-shell \"$PL volume 0.05-\"" \
    "#[fg=#d3869b]songfetch (spotify)" S "display-popup -E -S \"fg=#d3869b\" -w 55% -h 55% \"zsh -ic 'songfetch; read -k 1 -s'\"" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

panes)
  show "#[fg=#a89984,bold] panes" \
    "" \
    "#[fg=#a89984]split vertical"   "|" "split-window -h -c \"#{pane_current_path}\"" \
    "#[fg=#a89984]split horizontal" "-" "split-window -v -c \"#{pane_current_path}\"" \
    "#[fg=#a89984]zoom toggle"      z   "resize-pane -Z" \
    "#[fg=#a89984]kill pane"        x   "confirm-before -p \"kill pane? (y/n)\" kill-pane" \
    "#[fg=#a89984]cycle layouts"    Space "next-layout" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

windows)
  show "#[fg=#a89984,bold] windows" \
    "" \
    "#[fg=#a89984]new window"       c "new-window -c \"#{pane_current_path}\"" \
    "#[fg=#a89984]rename window"    , "command-prompt -I \"#W\" \"rename-window %%\"" \
    "#[fg=#a89984]kill window"      "&" "confirm-before -p \"kill window? (y/n)\" kill-window" \
    "#[fg=#a89984]next window"      ">" "next-window" \
    "#[fg=#a89984]previous window"  "<" "previous-window" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

sessions)
  show "#[fg=#89b482,bold] sessions" \
    "" \
    "#[fg=#89b482]project sessionizer" o "display-popup -E -w 60% -h 60% \"$D/scripts/tmux-sessionizer.sh\"" \
    "#[fg=#89b482]session picker"   s "display-popup -E -w 35% -h 30% \"$D/scripts/tmux-session-picker.sh\"" \
    "#[fg=#89b482]window tree"      w "display-popup -E -w 40% -h 40% \"$D/scripts/tmux-tree-picker.sh\"" \
    "#[fg=#89b482]detach"           d "detach-client" \
    "#[fg=#89b482]rename session"   "\$" "command-prompt -I \"#S\" \"rename-session %%\"" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

config)
  show "#[fg=#d4be98,bold] config" \
    "" \
    "#[fg=#d4be98]theme switcher"   T "display-popup -E -w 40% -h 40% \"$D/scripts/set-theme.sh\"" \
    "#[fg=#d4be98]reload config"    r "source-file ~/.tmux.conf ; display-message \"reloaded\"" \
    "#[fg=#d4be98]copy mode"        "[" "copy-mode" \
    "" \
    "$BACK_LABEL"           "$BACK_KEY" "$(nav root)"
  ;;

*)
  echo "usage: tmux-menu.sh [root|find|tools|markdown|nock|music|panes|windows|sessions|config]" >&2
  exit 1
  ;;
esac
