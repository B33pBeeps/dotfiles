#!/usr/bin/env bash
# Live-preview alacritty theme picker. Scroll through ~/.config/alacritty/themes
# with fzf — alacritty hot-reloads on each highlight. ESC reverts, ENTER keeps.
#
# Personal themes (e.g. tweaked catppuccin-macchiato.toml) are pinned to the top
# with a ★ prefix.

set -e

THEME_DIR="$HOME/.config/alacritty/themes/themes"
CONFIG="$HOME/.config/alacritty/alacritty.toml"
PERSONAL="$HOME/.config/alacritty/catppuccin-macchiato.toml"
STAR_LABEL="★ catppuccin-macchiato (personal)"

if [[ ! -d $THEME_DIR ]]; then
  echo "Themes not found at $THEME_DIR"
  echo "Clone with: git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes"
  exit 1
fi

ORIGINAL=$(grep -oE '"~/\.config/alacritty/[^"]+\.toml"' "$CONFIG" | head -1)
[[ -z $ORIGINAL ]] && { echo "Couldn't detect current theme import in $CONFIG"; exit 1; }

apply_theme() {
  local name="$1"
  local target
  if [[ $name == "$STAR_LABEL" ]]; then
    target='"~/.config/alacritty/catppuccin-macchiato.toml"'
  else
    target="\"~/.config/alacritty/themes/themes/${name}.toml\""
  fi
  sed -i --follow-symlinks -E "s|\"~/\.config/alacritty/[^\"]+\.toml\"|${target}|" "$CONFIG"
}

preview_theme() {
  local name="$1"
  if [[ $name == "$STAR_LABEL" ]]; then
    bat --color=always --language=toml "$PERSONAL"
  else
    bat --color=always --language=toml "$THEME_DIR/${name}.toml"
  fi
}

revert_theme() {
  sed -i --follow-symlinks -E "s|\"~/\.config/alacritty/[^\"]+\.toml\"|${ORIGINAL}|" "$CONFIG"
}

export -f apply_theme preview_theme
export CONFIG STAR_LABEL THEME_DIR PERSONAL

# Build the list: personal theme at top, then alphabetical themes
{
  [[ -f $PERSONAL ]] && printf '%s\n' "$STAR_LABEL"
  find "$THEME_DIR" -maxdepth 1 -name '*.toml' -printf '%f\n' | sed 's/\.toml$//' | sort
} > /tmp/.alacritty-theme-list

SELECTED=$(
  fzf < /tmp/.alacritty-theme-list \
      --prompt "theme> " \
      --header "live preview · ENTER keep · ESC revert" \
      --preview "bash -c 'preview_theme \"\$1\"' _ {}" \
      --preview-window 'right:55%:wrap' \
      --bind "focus:execute-silent(bash -c 'apply_theme \"\$1\"' _ {})"
) || true

rm -f /tmp/.alacritty-theme-list

if [[ -z $SELECTED ]]; then
  revert_theme
  echo "reverted"
else
  apply_theme "$SELECTED"
  echo "applied: $SELECTED"
fi
