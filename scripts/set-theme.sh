#!/usr/bin/env bash
# Global theme switcher — applies a palette across all themed configs.
# Usage: set-theme.sh catppuccin|gruvbox
#
# Files updated (in-place):
#   - zsh/.zshrc                  (fzf colors)
#   - tmux/.tmux.conf             (status, borders, popups, menus)
#   - oh-my-posh/zen.toml         (palette + segments)
#   - foot/foot.ini               (terminal colors)
#   - kitty/kitty.conf            (terminal colors)
#   - elio/theme.toml             (file manager colors)
#   - lazygit/config.yml          (git TUI colors)
#   - alacritty/alacritty.toml    (theme import line)
#   - bat/config                  (bat theme)
#   - scripts/tmux-*.sh           (ANSI colors in scripts)

set -e
THEME="${1:-}"
DOTFILES="$HOME/code/personal/dotfiles"
STATE_FILE="$HOME/.config/dotfiles-theme"

# Interactive picker when no arg given
if [[ -z $THEME ]]; then
  current="catppuccin"
  [[ -f $STATE_FILE ]] && current=$(<"$STATE_FILE")
  THEME=$(printf "catppuccin\ngruvbox" | fzf \
    --prompt "theme> " \
    --header "current: ${current}" \
    --height 30% \
    --reverse \
    --no-preview) || exit 0
fi

if [[ "$THEME" != "catppuccin" && "$THEME" != "gruvbox" ]]; then
  echo "Unknown theme: $THEME"
  echo "Usage: $0 [catppuccin|gruvbox]   (no arg = picker)"
  exit 1
fi

# ─── Catppuccin Macchiato → Gruvbox Material color map ────────────────
# Format: catppuccin_hex gruvbox_hex (one pair per line)
declare -a MAP=(
  "#24273a #282828"   # base / bg0
  "#1e2030 #1d2021"   # mantle / bg_hard
  "#181926 #1d2021"   # crust / bg_hard
  "#363a4f #32302f"   # surface0 / bg1
  "#494d64 #45403d"   # surface1 / bg3
  "#5b6078 #5a524c"   # surface2 / bg5
  "#6e738d #7c6f64"   # overlay0 / grey0
  "#8087a2 #928374"   # overlay1 / grey1
  "#939ab7 #a89984"   # overlay2 / grey2
  "#cad3f5 #d4be98"   # text / fg
  "#b8c0e0 #d4be98"   # subtext1 / fg
  "#a5adcb #ddc7a1"   # subtext0 / fg_dim
  "#f4dbd6 #ddc7a1"   # rosewater / fg_dim
  "#f0c6c6 #ea6962"   # flamingo / red
  "#f5bde6 #d3869b"   # pink / purple
  "#c6a0f6 #d3869b"   # mauve / purple
  "#ed8796 #ea6962"   # red
  "#ee99a0 #ea6962"   # maroon / red
  "#f5a97f #e78a4e"   # peach / orange
  "#eed49f #d8a657"   # yellow
  "#a6da95 #a9b665"   # green
  "#8bd5ca #89b482"   # teal / aqua
  "#91d7e3 #89b482"   # sky / aqua
  "#7dc4e4 #7daea3"   # sapphire / blue
  "#8aadf4 #7daea3"   # blue
  "#b7bdf8 #d3869b"   # lavender / purple
)

# Files to process
FILES=(
  "$DOTFILES/zsh/.zshrc"
  "$DOTFILES/tmux/.tmux.conf"
  "$DOTFILES/oh-my-posh/zen.toml"
  "$DOTFILES/foot/foot.ini"
  "$DOTFILES/kitty/kitty.conf"
  "$DOTFILES/elio/theme.toml"
  "$DOTFILES/lazygit/config.yml"
  "$DOTFILES/scripts/tmux-quota.sh"
  "$DOTFILES/scripts/tmux-session-picker.sh"
  "$DOTFILES/scripts/tmux-tree-picker.sh"
  "$DOTFILES/scripts/tmux-menu.sh"
)

# foot.ini uses raw hex without # — strip pound for those files
needs_unhashed() {
  [[ "$1" == *"foot.ini" ]] || [[ "$1" == *"kitty.conf" ]]
}

apply_map() {
  local from_idx=$1 to_idx=$2
  for file in "${FILES[@]}"; do
    [[ ! -f $file ]] && continue
    local tmp=$(mktemp)
    cp "$file" "$tmp"
    for pair in "${MAP[@]}"; do
      local from=$(echo "$pair" | awk "{print \$$from_idx}")
      local to=$(echo "$pair" | awk "{print \$$to_idx}")
      sed -i --follow-symlinks "s|${from}|${to}|gi" "$tmp"
      # Also handle unhashed versions for foot/kitty
      if needs_unhashed "$file"; then
        local from_nh="${from#\#}"
        local to_nh="${to#\#}"
        sed -i --follow-symlinks "s|${from_nh}|${to_nh}|gi" "$tmp"
      fi
    done
    # Write back through symlink
    cat "$tmp" > "$file"
    rm "$tmp"
  done
}

# Alacritty import + bat theme (separate, non-hex changes)
update_aux() {
  local target_theme="$1"
  local alacritty_import bat_theme
  if [[ $target_theme == catppuccin ]]; then
    alacritty_import='~/.config/alacritty/catppuccin-macchiato.toml'
    bat_theme='Catppuccin-macchiato'
  else
    alacritty_import='~/.config/alacritty/themes/themes/gruvbox_material.toml'
    bat_theme='gruvbox-dark'
  fi
  sed -i --follow-symlinks -E "s|\"~/\.config/alacritty/[^\"]+\.toml\"|\"${alacritty_import}\"|" "$DOTFILES/alacritty/alacritty.toml"
  echo "--theme=\"${bat_theme}\"" > "$DOTFILES/bat/config"
}

if [[ $THEME == gruvbox ]]; then
  apply_map 1 2   # Catppuccin → Gruvbox
  update_aux gruvbox
  echo "✓ Applied Gruvbox Material"
else
  apply_map 2 1   # Gruvbox → Catppuccin
  update_aux catppuccin
  echo "✓ Applied Catppuccin Macchiato"
fi

# Save theme state (nvim reads this)
echo "$THEME" > "$STATE_FILE"

# Reload tmux if running and force a repaint
if tmux source-file ~/.tmux.conf 2>/dev/null; then
  tmux refresh-client 2>/dev/null
  echo "  tmux reloaded + repainted"
fi

echo ""
echo "→ Run 'exec zsh' to apply fzf colors in this shell"
echo "→ Open new terminals for full effect"
echo "→ nvim: re-themes itself on next focus (no restart needed)"
